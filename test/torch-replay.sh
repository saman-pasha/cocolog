#!/bin/sh
# The graph path on a CUDA device: forced values living there, and a
# recurring forward replayed as one CUDA graph -- DESIGN-lazy-graph.md, gate C.
#
#   sh test/torch-replay.sh          SKIPs where torch_cuda_available(false)
#
# WHAT IS BEING CHECKED. Under torch_execution(graph) with torch_device(cuda)
# a leaf moves to the device the first time a deferred node reads it, and the
# forced values stay there; consumers copy back. So every producer must answer
# what the CPU path answers, WITHIN A TOLERANCE -- a GPU's kernels are not the
# CPU's, and bit equality is the CPU gate's claim, not this one's. Then a
# forward forced again and again on fresh leaves must be captured the second
# time and replayed after that, with tensor_graph_stats/1 saying so and the
# numbers unchanged; a closure with a parameter in it must never be captured,
# since a replay builds no tape, and its gradients must still be right. Last,
# tutorial 29's heavy goal runs on both devices and must agree.
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
if ! timeout 30 "$C" query "use_module(library(torch)), torch_cuda_available(B), write(B), nl" 2>/dev/null \
     | grep -aq '^true$'; then
  echo "SKIP (no CUDA device here -- this gate runs on the Colab T4)"
  exit 0
fi
U="use_module(library(torch))"
q() { timeout 300 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
GPU="torch_execution(graph), torch_device(cuda), torch_seed(11)"
CPU="torch_execution(eager), torch_device(cpu), torch_seed(11)"
# the largest |a - b| over two flat lists joined by `/' -- not `-', which is also a
# minus sign and made every list with a negative value compare as garbage
maxdiff() { echo "$1" | tr -d '[]' | awk -F'/' '{ n = split($1, a, ","); split($2, b, ",");
  m = 0; for (i = 1; i <= n; i++) { d = a[i] - b[i]; if (d < 0) d = -d; if (d > m) m = d }
  printf "%.2e", m }'; }
# one goal on the T4 and on the CPU; the two flat answers within TOL
near() {
  g=$(q "$GPU, $2"); c=$(q "$CPU, $2")
  d=$(maxdiff "$g/$c")
  check "$1" "$(awk -v d="$d" -v t="$3" 'BEGIN { print (d <= t) ? "within " t : "off by " d }')" "within $3"
}
LEAVES="tensor_new([2,3], randn, A), tensor_new([3,2], randn, B), tensor_new([2,3], randn, A2)"
FLAT="tensor_reshape(R, [-1], F), tensor_to_list(F, L), write(answer(L)), nl"

echo "-- the device: $(q "torch_device(cuda), torch_current_device(D), write(answer(D)), nl")"
check "a forced value answers through the CPU seam" \
  "$(q "$GPU, tensor_zeros([2,2], A), tensor_scalar(add, A, 1.5, B), tensor_to_list(B, L), write(answer(L)), nl")" \
  "[[1.5,1.5],[1.5,1.5]]"

echo
echo "-- every producer, on the T4, within 1e-4 of the CPU path"
for op in neg abs exp log sqrt relu sigmoid tanh transpose; do
  near "unary $op" "$LEAVES, tensor_unary($op, A, R), $FLAT" 1e-4
done
for op in add sub mul div pow; do
  near "scalar $op" "$LEAVES, tensor_scalar($op, A, 2.5, R), $FLAT" 1e-4
done
for op in add sub mul div; do
  near "binary $op" "$LEAVES, tensor_binary($op, A, A2, R), $FLAT" 1e-4
done
near "binary matmul" "$LEAVES, tensor_binary(matmul, A, B, R), $FLAT" 1e-4
near "argmax" "$LEAVES, tensor_argmax(A, 1, R), $FLAT" 0
near "reshape" "$LEAVES, tensor_reshape(A, [3,2], R), $FLAT" 0
near "cat" "$LEAVES, tensor_cat([A, A2], 0, R), $FLAT" 0
near "index_rows" "$LEAVES, tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), $FLAT" 0
near "rows and cols" "$LEAVES, tensor_rows(A, 1, 2, R0), tensor_cols(R0, 0, 2, R), $FLAT" 0
near "standardise" "$LEAVES, tensor_standardise(A, 2, R), $FLAT" 1e-4
near "agg mean, through a chain" "$LEAVES, tensor_scalar(mul, A, 2.0, X), tensor_unary(relu, X, Y), tensor_agg(mean, Y, R), $FLAT" 1e-4
near "an eleven-op expression" \
  "$LEAVES, tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_unary(abs, X7, X8), tensor_reshape(X8, [4], R), $FLAT" 1e-4

echo
echo "-- a recurring forward: plain once, captured the second time, replayed after"
FWD="tensor_randn([256, 64], X), tensor_randn([64, 16], W), tensor_binary(matmul, X, W, H), tensor_unary(relu, H, R1), tensor_scalar(mul, R1, 0.5, Q), tensor_agg(sum, Q, T), tensor_item(T, S)"
check "six forces: 4 nodes executed once, 5 replays, none pending" \
  "$(q "$GPU, findall(S, (between(1, 6, _), $FWD), _), tensor_graph_stats(stats(recorded(Rc), executed(Ex), replayed(Rp), pending(P))), write(answer(Rc-Ex-Rp-P)), nl")" \
  "24-4-5-0"
near "and the six sums match the CPU path" \
  "findall(S, (between(1, 6, _), $FWD), Ss), tensor_from_list(Ss, R), $FLAT" 0.5
check "a different shape is a different key: no replay across it" \
  "$(q "$GPU, tensor_randn([8, 4], X1), tensor_scalar(mul, X1, 2.0, A1), tensor_unary(relu, A1, B1), tensor_to_list(B1, _), tensor_randn([9, 4], X2), tensor_scalar(mul, X2, 2.0, A2), tensor_unary(relu, A2, B2), tensor_to_list(B2, _), tensor_graph_stats(stats(_, executed(Ex), replayed(Rp), _)), write(answer(Ex-Rp)), nl")" \
  "4-0"
check "a closure with a parameter is never captured" \
  "$(q "$GPU, tensor_randn([64, 3], X), tensor_from_list([[1.0],[-2.0],[0.5]], W0), tensor_parameter(W0, W), findall(L, (between(1, 4, _), tensor_binary(matmul, X, W, P), tensor_binary(mul, P, P, P2), tensor_agg(mean, P2, M), tensor_item(M, L), tensor_grad(M, [W], [G]), tensor_free(G)), _), tensor_graph_stats(stats(_, _, replayed(Rp), _)), write(answer(Rp)), nl")" \
  "0"
near "and its gradient on the device matches the CPU's" \
  "tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [G]), tensor_reshape(G, [2], R), $FLAT" 1e-5

echo
echo "-- tutorial 29's heavy goal, both devices"
cpu=$(timeout 900 "$C" run "$ROOT/tutorials/torch/29-sgd-by-hand.pl" "torch_device(cpu), torch_execution(graph), heavy(20000, 32, 100)" 2>&1 | grep -a '^heavy')
T0=$(date +%s)
gpu=$(timeout 900 "$C" run "$ROOT/tutorials/torch/29-sgd-by-hand.pl" "torch_device(cuda), torch_execution(graph), heavy(20000, 32, 100)" 2>&1 | grep -a '^heavy')
echo "     cpu:  $(echo "$cpu" | sed 's/^heavy [0-9]* rows [0-9]* features [0-9]* steps //')"
echo "     cuda: $(echo "$gpu" | sed 's/^heavy [0-9]* rows [0-9]* features [0-9]* steps //')  ($(( $(date +%s) - T0 ))s)"
check "the heavy loop reaches the same loss on both devices" \
  "$(echo "$gpu" | grep -aoE 'final mse [0-9.]+' )" "$(echo "$cpu" | grep -aoE 'final mse [0-9.]+')"
check "and the same distance from the plane" \
  "$(echo "$gpu" | grep -aoE 'plane\| [0-9.]+' )" "$(echo "$cpu" | grep -aoE 'plane\| [0-9.]+')"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"; exit 1
fi
