#!/bin/sh
# Autograd through library(torch), from Prolog: tensor_parameter/2,
# tensor_agg/3, tensor_grad/3, tensor_step/4 -- DESIGN-lazy-graph.md, gate B.
#
#   sh test/torch-grad.sh
#
# WHAT IS BEING CHECKED. A gradient is a number libtorch computes from a
# tape it recorded while the loss was computed. Three things can go wrong
# with that from Prolog, and each has a check here: the tape may not be
# there (a loss built from deferred nodes must be FORCED before it is
# differentiated, and forcing is what builds the tape); the number may be
# wrong (so one gradient is held to the analytic formula, and one to a
# hand-computable constant, exactly); and the two execution paths may
# disagree (so every check that can run under both does, and demands
# equality). Then thirty steps of plain SGD have to reach a known line, and
# a step must be a NEW leaf that leaves the old parameter as it was.
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"
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
[ -f "$ROOT/library/torch.so" ] || {
  echo "SKIP (no library/torch.so -- sh modules/torch/build.sh)"; exit 0; }
if ! timeout 20 "$C" query "use_module(library(torch)), tensor_zeros([1], Z), tensor_parameter(Z, _), write(ok), nl" 2>/dev/null \
     | grep -aq '^ok$'; then
  echo "SKIP (library(torch) has no tensor_parameter/2)"
  exit 0
fi
U="use_module(library(torch))"
q() { timeout 120 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
qn() { q "$1" | sed -E 's/_G[0-9]+/_/g'; }
both() {
  e=$(q "tensor_execution(torch, eager), torch_seed(11), $2")
  g=$(q "tensor_execution(torch, graph), torch_seed(11), $2")
  check "$1" "$g" "$e"
}
# the largest |a - b| over two flat lists printed as answer(La/Lb) -- `/', because
# `-' is also a minus sign and splitting on it compared nothing when a value was
# negative; awk, not python
maxdiff() { echo "$1" | tr -d '[]' | awk -F'/' '{ n = split($1, a, ","); split($2, b, ",");
  m = 0; for (i = 1; i <= n; i++) { d = a[i] - b[i]; if (d < 0) d = -d; if (d > m) m = d }
  printf "%.2e", m }'; }

echo "-- a gradient is a number libtorch computed, and it is the right one"
both "the gradient of sum(W*W) is exactly 2W" \
  "tensor_from_list([1.0, -2.0, 3.5], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(LG)), nl"
check "and it is [2.0,-4.0,7.0]" \
  "$(q "tensor_from_list([1.0, -2.0, 3.5], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(LG)), nl")" \
  "[2.0,-4.0,7.0]"
# least squares: d/dW mean((XW - Y)^2) = (2/N) X^T (XW - Y), computed with the same ops
LSQ="tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [G]), tensor_unary(transpose, X, XT), tensor_binary(matmul, XT, D, A0), tensor_scalar(mul, A0, 0.5, A), tensor_reshape(G, [2], G1), tensor_reshape(A, [2], A1), tensor_to_list(G1, LG), tensor_to_list(A1, LA), write(answer(LG/LA)), nl"
d=$(maxdiff "$(q "$LSQ")")
check "least squares: autograd within 1e-6 of the analytic gradient" \
  "$(awk -v d="$d" 'BEGIN { print (d < 1e-6) ? "within" : "off by " d }')" "within"
both "and the two execution paths agree on it exactly" "$LSQ"
both "a parameter the loss never touched gets zeros" \
  "tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_from_list([5.0, 5.0, 5.0], V0), tensor_parameter(V0, V), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W, V], [_, GV]), tensor_to_list(GV, LV), write(answer(LV)), nl"
both "two gradients of one loss are the same gradient" \
  "tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_scalar(pow, W, 3.0, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G1]), tensor_grad(L, [W], [G2]), tensor_to_list(G1, L1), tensor_to_list(G2, L2), write(answer(L1-L2)), nl"
both "a loss read as a number first is still differentiable" \
  "tensor_from_list([2.0], W0), tensor_parameter(W0, W), tensor_scalar(pow, W, 2.0, S), tensor_agg(sum, S, L), tensor_item(L, V), tensor_grad(L, [W], [G]), tensor_to_list(G, LG), write(answer(V-LG)), nl"

echo
echo "-- a step is a new leaf; the old parameter stands"
both "W2 = W - lr*G, exactly, and W is untouched" \
  "tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_to_list(W, LW), tensor_to_list(W2, LW2), write(answer(LW-LW2)), nl"
check "and the numbers are those" \
  "$(q "tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_to_list(W, LW), tensor_to_list(W2, LW2), write(answer(LW-LW2)), nl")" \
  "[1.0,-2.0]-[0.5,-1.0]"
both "the new leaf differentiates on its own" \
  "tensor_from_list([1.0, -2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, L), tensor_grad(L, [W], [G]), tensor_step(W, G, 0.25, W2), tensor_binary(mul, W2, W2, S2), tensor_agg(sum, S2, L2), tensor_grad(L2, [W2], [G2]), tensor_to_list(G2, LG2), write(answer(LG2)), nl"

echo
echo "-- what is refused, and how"
check "a loss that is not one number" \
  "$(qn "tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), catch(tensor_grad(S, [W], _), error(E, _), true), write(answer(E)), nl")" \
  "domain_error(scalar_tensor,3)"
check "a loss no parameter reaches" \
  "$(qn "tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_zeros([2], Z), tensor_agg(sum, Z, L), catch(tensor_grad(L, [W], _), error(E, _), true), write(answer(E)), nl")" \
  "domain_error(differentiable,4)"
check "tensor_agg over the same five reductions answers as tensor_reduce" \
  "$(q "tensor_from_list([1.0, 2.0, 3.0, 4.0], T), findall(V, (member(Op, [sum, mean, max, min, std]), tensor_agg(Op, T, A), tensor_item(A, V)), Vs), findall(V, (member(Op, [sum, mean, max, min, std]), tensor_reduce(Op, T, V)), Rs), ( Vs == Rs -> R = same ; R = differ(Vs, Rs) ), write(answer(R)), nl")" \
  "same"

echo
echo "-- thirty steps of SGD, written in Prolog, reach the line"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-torch-grad-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM
cat > "$OUT/sgd.pl" <<'PL'
:- use_module(library(torch)).
% x in (-1,1) from the sin-hash; y = 3 x1 - 2 x2 + 0.5 x3 + 1, no noise
noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S), !.
row(I, [X1, X2, X3], [Y]) :-
    noise(I, X1), J is I + 1000, noise(J, X2), K is I + 2000, noise(K, X3),
    Y is 3*X1 - 2*X2 + 0.5*X3 + 1, !.
data(N, X, Y) :-
    N1 is N - 1,
    findall(R, (between(0, N1, I), row(I, R, _)), XR),
    findall(R, (between(0, N1, I), row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y), !.
step(X, Y, W, B, LR, W2, B2, Loss) :-
    tensor_binary(matmul, X, W, XW), tensor_binary(add, XW, B, P),
    tensor_binary(sub, P, Y, D), tensor_binary(mul, D, D, D2),
    tensor_agg(mean, D2, L), tensor_item(L, Loss),
    tensor_grad(L, [W, B], [GW, GB]),
    tensor_step(W, GW, LR, W2), tensor_step(B, GB, LR, B2),
    tensor_free(XW), tensor_free(P), tensor_free(D), tensor_free(D2),
    tensor_free(L), tensor_free(GW), tensor_free(GB), tensor_free(W), tensor_free(B).
sgd(0, _, _, W, B, _, W, B, Loss, Loss) :- !.
sgd(K, X, Y, W, B, LR, WF, BF, _, LossF) :-
    step(X, Y, W, B, LR, W2, B2, Loss), K1 is K - 1,
    sgd(K1, X, Y, W2, B2, LR, WF, BF, Loss, LossF).
main(Mode) :-
    tensor_execution(Mode),
    data(64, X, Y),
    tensor_zeros([3, 1], W0), tensor_parameter(W0, W1),
    tensor_zeros([1], B0), tensor_parameter(B0, B1),
    step(X, Y, W1, B1, 0.3, _, _, First),
    tensor_parameter(W0, W), tensor_parameter(B0, B),
    sgd(30, X, Y, W, B, 0.3, WF, BF, none, Last),
    tensor_to_list(WF, LW), tensor_to_list(BF, LB),
    tensor_graph_stats(S),
    format("first ~6f last ~6f~n", [First, Last]),
    format("w ~w b ~w~n", [LW, LB]),
    ( Last < First / 20 -> write(fell), nl ; write(did_not_fall), nl ),
    LW = [[W1v], [W2v], [W3v]], LB = [Bv],
    ( abs(W1v - 3) < 0.15, abs(W2v + 2) < 0.15, abs(W3v - 0.5) < 0.15, abs(Bv - 1) < 0.15
    -> write(near_the_line), nl ; write(far_from_the_line), nl ),
    write(S), nl.
PL
e=$(timeout 300 "$C" run "$OUT/sgd.pl" "main(eager)" 2>&1 | tr -d '\r')
g=$(timeout 300 "$C" run "$OUT/sgd.pl" "main(graph)" 2>&1 | tr -d '\r')
check "the loss fell by twenty times or more" "$(echo "$e" | grep -a -m1 -E 'fell|did_not_fall')" "fell"
check "and the weights are within 0.15 of 3, -2, 0.5 and 1" "$(echo "$e" | grep -a -m1 -E 'the_line')" "near_the_line"
check "thirty steps under graph print the same as under eager" \
  "$(echo "$g" | grep -avE '^stats')" "$(echo "$e" | grep -avE '^stats')"
check "and the graph path recorded and executed every node, none pending" \
  "$(echo "$g" | grep -a '^stats' | sed -E 's/stats\(recorded\(([0-9]+)\),executed\(([0-9]+)\),replayed\([0-9]+\),pending\(([0-9]+)\)\)/\1 \2 \3/' | awk '{ print ($1 == $2 && $3 == 0) ? "all executed, none pending" : "recorded " $1 " executed " $2 " pending " $3 }')" \
  "all executed, none pending"

echo
echo "-- the device, third: auto, whichever this machine has, and a parameter read twice"
# `auto' is cuda:0 where there is a card and cpu elsewhere. A parameter the
# loss reads TWICE must stay one leaf across both reads, under either path
# -- on a T4 it did not: `cuda' with no index compared unequal to `cuda:0'
# and every touch re-made the parameter, so the gradient reached nothing
# and thirty tutorials trained to chance without an error. Here the
# gradient of sum(W*W) + sum(W) at W = [1, 2] is 2W + 1, both paths.
check "sum(W*W) + sum(W) differentiates to 2W + 1 under eager auto" \
  "$(q "tensor_execution(torch, eager, auto), tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, A), tensor_agg(sum, W, B), tensor_binary(add, A, B, L), tensor_grad(L, [W], [G]), tensor_to_list(G, GL), write(answer(GL)), nl")" \
  "[3.0,5.0]"
check "and under graph auto" \
  "$(q "tensor_execution(torch, graph, auto), tensor_from_list([1.0, 2.0], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, S), tensor_agg(sum, S, A), tensor_agg(sum, W, B), tensor_binary(add, A, B, L), tensor_grad(L, [W], [G]), tensor_to_list(G, GL), write(answer(GL)), nl")" \
  "[3.0,5.0]"
# a value made BEFORE the switch follows it: the other library does this on
# its own, and the graph path always did at force; eager places at the read
check "a tensor made under cpu is read by an op under eager auto" \
  "$(q "tensor_execution(torch, eager, cpu), tensor_from_list([[1.0, 2.0]], X), tensor_execution(torch, eager, auto), tensor_from_list([[1.0], [1.0]], Y), tensor_binary(matmul, X, Y, Z), tensor_to_list(Z, ZL), write(answer(ZL)), nl")" \
  "[[3.0]]"
check "and its eager and graph fits of tutorial 31 agree under auto" \
  "$(D=$(mktemp -d); timeout 300 "$C" --kb tutorials --embed "$D" run "$ROOT/tutorials/tensor/31-tensor-expressions.pl" "tensor_execution(torch, graph, auto), train" 2>&1 | grep -ac '^identical'; rm -rf "$D")" \
  "1"

echo
echo "-- exec/1 frees what a procedure made, even when an input is the same integer"
# Handles start at 1 and a freed slot is reused, so in a fresh process the
# first tensor a procedure makes IS handle 1 -- and `exec(p(1))', with the 1
# a count, once read that 1 as a handle to keep: a tensor kept alive by a
# hyperparameter that happened to equal its number. Only the head's outputs
# can carry a handle the call made; an input never can, and is not searched.
# The rules are asserted as their translated clauses, `V = E' being =//2.
TE="use_module(library(tensor_expr)), assertz((te_gate_count(N, S0, S) :- '='(_, zeros([N]), S0, S))), assertz((te_gate_return(N, T, S0, S) :- '='(T, zeros([N]), S0, S)))"
check "a count of 1 in the head does not keep handle 1 alive" \
  "$(q "$TE, exec(te_gate_count(1)), ( catch(tensor_shape(1, _), _, fail) -> A = kept ; A = freed ), write(answer(A)), nl")" \
  "freed"
check "and handle 1 returned through the head is kept, with its shape" \
  "$(q "$TE, exec(te_gate_return(1, H)), tensor_shape(H, Sh), write(answer(H-Sh)), nl")" \
  "1-[1]"

echo
echo "-- use_module lends the library's operators to the file that names it"
# The operator table is the process's, and a library's `:- op' reached a
# file only when the library's clauses were consulted -- at the first goal,
# after the file had been read whole -- so every tensor program opened with
# the library's three declarations copied out. The load applies them as the
# directive runs now. This file writes `:=' and `matmul' with no op/3 of its
# own, and is consulted by `run', which is how a program is read.
LD=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-lend-XXXXXX")
cat > "$LD/lent.pl" <<'PL'
:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
lent(L) :- X := [[1.0, 2.0]] matmul [[3.0], [4.0]], L := list(X).
PL
check "a file with no op/3 of its own reads := and matmul after use_module" \
  "$(timeout 120 "$C" --local run "$LD/lent.pl" "lent(L), write(answer(L)), nl" 2>&1 | grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//')" \
  "[[11.0]]"
rm -rf "$LD"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"; exit 1
fi
