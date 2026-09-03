#!/bin/sh
# library(tensorflow): the tensor_* predicates over TensorFlow's C library, as
# the second backend behind tensor_execution(Backend, Mode).
#
#   sh test/tensorflow.sh          SKIPs where library/tensorflow.so is not built
#
# WHAT IS BEING CHECKED. Under tensor_execution(tensorflow, eager) every
# producer answers what the torch backend answers, within a tolerance -- two
# libraries' kernels, not one. Under (tensorflow, graph) a loss built of the
# predicates differentiates through TF_AddGradients to the analytic gradient,
# a step answers a new parameter, a random leaf read twice is one draw, and a
# shape is known with nothing executed. Under (tensorflow, eager) the same
# gradients come out -- the recorded structure compiled and differentiated
# the same way, after the values are already there -- and a loss read by
# item first still differentiates. Last, tutorial 31's fit under tensorflow,
# eager then graph in one process, is IDENTICAL across its two paths and
# reaches torch's numbers within a tolerance -- the same program, the other
# library.
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"
failures=0
check() {
  if [ "$2" = "$3" ]; then printf 'ok   %-56s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else printf 'FAIL %-56s\n     got  %s\n     want %s\n' "$1" "$2" "$3"; failures=$((failures + 1)); fi
}
[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }
[ -f "$ROOT/library/torch.so" ] || { echo "SKIP (no library/torch.so)"; exit 0; }
[ -f "$ROOT/library/tensorflow.so" ] || { echo "SKIP (no library/tensorflow.so -- sh modules/tensorflow/build.sh)"; exit 0; }
U="use_module(library(torch)), use_module(library(tensorflow))"
q() { timeout 300 "$C" query "$U, $1" 2>/dev/null | grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
TF="tensor_execution(tensorflow, eager), tensorflow_seed(11), torch_seed(11)"
TORCH="tensor_execution(torch, eager), torch_seed(11), tensorflow_seed(11)"
maxdiff() { echo "$1" | tr -d '[]' | awk -F'/' '{ n = split($1, a, ","); split($2, b, ",");
  m = 0; for (i = 1; i <= n; i++) { d = a[i] - b[i]; if (d < 0) d = -d; if (d > m) m = d }
  printf "%.2e", m }'; }
# the same goal on both backends, with the same leaves written out, within TOL
LEAVES="tensor_from_list([[0.5, -1.0, 2.0], [1.5, 0.25, -0.75]], A), tensor_from_list([[1.0, 2.0], [-1.0, 0.5], [0.0, 1.0]], B), tensor_from_list([[2.0, 1.0, -1.0], [0.5, 0.5, 0.5]], A2)"
FLAT="tensor_reshape(R, [-1], F), tensor_to_list(F, L), write(answer(L)), nl"
near() {
  t=$(q "$TF, $2"); o=$(q "$TORCH, $2")
  d=$(maxdiff "$t/$o")
  check "$1" "$(awk -v d="$d" -v t="$3" 'BEGIN { print (d <= t) ? "within " t : "off by " d }')" "within $3"
}
echo "-- $(q "tensorflow_version(V), write(answer(V)), nl") is the TensorFlow; the switch answers $(q "$TF, tensor_execution(B, M), write(answer(B-M)), nl")"
echo
echo "-- every producer under (tensorflow, eager), within 1e-5 of the torch backend"
for op in neg abs exp relu sigmoid tanh transpose; do
  near "unary $op" "$LEAVES, tensor_unary($op, A, R), $FLAT" 1e-5
done
near "unary log, on a positive tensor" "$LEAVES, tensor_unary(abs, A, P), tensor_scalar(add, P, 1.0, Q), tensor_unary(log, Q, R), $FLAT" 1e-5
near "unary sqrt, likewise" "$LEAVES, tensor_unary(abs, A, P), tensor_unary(sqrt, P, R), $FLAT" 1e-5
for op in add sub mul div pow; do
  near "scalar $op" "$LEAVES, tensor_scalar($op, A, 2.5, R), $FLAT" 1e-5
done
for op in add sub mul div; do
  near "binary $op" "$LEAVES, tensor_binary($op, A, A2, R), $FLAT" 1e-5
done
near "binary matmul" "$LEAVES, tensor_binary(matmul, A, B, R), $FLAT" 1e-5
for op in sum mean max min std; do
  near "agg $op" "$LEAVES, tensor_agg($op, A, R), $FLAT" 1e-5
done
near "argmax" "$LEAVES, tensor_argmax(A, 1, R), $FLAT" 0
near "reshape" "$LEAVES, tensor_reshape(A, [3, 2], R), $FLAT" 0
near "cat" "$LEAVES, tensor_cat([A, A2], 0, R), $FLAT" 0
near "index_rows" "$LEAVES, tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), $FLAT" 0
near "rows and cols" "$LEAVES, tensor_rows(A, 1, 2, R0), tensor_cols(R0, 0, 2, R), $FLAT" 0
near "standardise" "$LEAVES, tensor_standardise(A, 2, R), $FLAT" 1e-5
near "eye, arange, full" "tensor_eye(3, E), tensor_arange(3, Ar), tensor_full([3], 2.0, Fu), tensor_reshape(Ar, [3, 1], Ar2), tensor_binary(matmul, E, Ar2, X1), tensor_reshape(Fu, [3, 1], Fu2), tensor_binary(add, X1, Fu2, R), $FLAT" 0
near "a ten-op expression" "$LEAVES, tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_agg(mean, X7, R), $FLAT" 1e-4
check "a shape asks nothing of the values" "$(q "$TF, $LEAVES, tensor_shape(A, S), write(answer(S)), nl")" "[2,3]"
check "a random leaf is drawn once, whichever backend" "$(q "$TF, tensor_new([2, 3], randn, R), tensor_to_list(R, L1), tensor_to_list(R, L2), (L1 == L2 -> write(answer(same)) ; write(answer(different))), nl")" "same"

echo
echo "-- under (tensorflow, graph): the gradient, the step, the shape before anything runs"
G="tensor_execution(tensorflow, graph), tensorflow_seed(11)"
LSQ="tensor_from_list([[1.0, 2.0], [0.5, -1.0], [-2.0, 0.25], [3.0, 1.0]], X), tensor_from_list([[1.0], [0.0], [-1.0], [2.0]], Y), tensor_from_list([[0.3], [-0.7]], W0), tensor_parameter(W0, W), tensor_binary(matmul, X, W, XW), tensor_binary(sub, XW, Y, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_reshape(Gr, [-1], F), tensor_to_list(F, GL), write(answer(GL)), nl"
lsq_tf=$(q "$G, $LSQ"); lsq_to=$(q "$TORCH, $LSQ"); lsq_d=$(maxdiff "$lsq_tf/$lsq_to")
check "the least-squares gradient, within 1e-5 of torch's" "$(awk -v d="$lsq_d" 'BEGIN { print (d <= 1e-5) ? "within 1e-5" : "off by " d }')" "within 1e-5"
check "grad of sum(W*W) is 2W, exactly" "$(q "$G, tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(GL)), nl")" "[[3.0],[-4.0]]"
check "a parameter the loss never reached gets zeros" "$(q "$G, tensor_from_list([1.0, 2.0], A0), tensor_parameter(A0, A), tensor_from_list([1.0], U0), tensor_parameter(U0, U), tensor_agg(sum, A, L), tensor_grad(L, [A, U], [_, GU]), tensor_to_list(GU, GL), write(answer(GL)), nl")" "[0.0]"
check "a step is a new leaf: W - 0.5 G from W = 1 on (w - 3)^2 is 3" "$(q "$G, tensor_from_list([1.0], W0), tensor_parameter(W0, W), tensor_scalar(sub, W, 3.0, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_step(W, Gr, 0.5, W2), tensor_to_list(W2, L2), write(answer(L2)), nl")" "[3.0]"
check "the shape of a matmul, executed nothing" "$(q "$G, tensor_new([3, 4], zeros, A), tensor_new([4, 5], ones, B), tensor_binary(matmul, A, B, C), tensor_shape(C, S), tensor_graph_stats(stats(_, executed(E), _, _)), write(answer(S-E)), nl")" "[3,5]-0"
check "a shape error is refused when the op is added" "$(q "$G, tensor_new([3, 4], zeros, A), tensor_new([5, 6], ones, B), catch((tensor_binary(matmul, A, B, _), write(answer(accepted))), error(domain_error(_, _), _), write(answer(refused))), nl")" "refused"

echo
echo "-- under (tensorflow, eager): the same gradients, from the tape the recorded structure is"
E="tensor_execution(tensorflow, eager), tensorflow_seed(11)"
lsq_e=$(q "$E, $LSQ"); lsq_ed=$(maxdiff "$lsq_e/$lsq_to")
check "the least-squares gradient under eager, within 1e-5 of torch's" "$(awk -v d="$lsq_ed" 'BEGIN { print (d <= 1e-5) ? "within 1e-5" : "off by " d }')" "within 1e-5"
check "grad of sum(W*W) under eager is 2W, exactly" "$(q "$E, tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(GL)), nl")" "[[3.0],[-4.0]]"
check "a loss read by item first still differentiates, under eager" "$(q "$E, tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_item(L, V), tensor_grad(L, [W], [Gr]), tensor_to_list(Gr, GL), write(answer(V-GL)), nl")" "6.25-[[3.0],[-4.0]]"
check "a step under eager: W - 0.5 G from W = 1 on (w - 3)^2 is 3" "$(q "$E, tensor_from_list([1.0], W0), tensor_parameter(W0, W), tensor_scalar(sub, W, 3.0, D), tensor_binary(mul, D, D, D2), tensor_agg(mean, D2, L), tensor_grad(L, [W], [Gr]), tensor_step(W, Gr, 0.5, W2), tensor_to_list(W2, L2), write(answer(L2)), nl")" "[3.0]"
check "a parameter the loss never reached gets zeros, under eager" "$(q "$E, tensor_from_list([1.0, 2.0], A0), tensor_parameter(A0, A), tensor_from_list([1.0], U0), tensor_parameter(U0, U), tensor_agg(sum, A, L), tensor_grad(L, [A, U], [_, GU]), tensor_to_list(GU, GL), write(answer(GL)), nl")" "[0.0]"
check "the device, third: cuda asked for on a machine without one runs on cpu, and says so" "$(timeout 300 "$C" query "$U, tensor_execution(tensorflow, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl" 2>&1 | grep -a 'running on cpu' | grep -ac tensorflow)-$(q "$E, tensor_execution(tensorflow, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl")" "$( [ "$(q "tensor_execution(tensorflow, eager, cuda), tensor_execution(_, _, D), write(answer(D)), nl")" = cuda ] && echo "0-tensorflow-eager-cuda" || echo "1-tensorflow-eager-cpu" )"
check "auto is cuda where there is one and cpu elsewhere, quietly" "$(timeout 300 "$C" query "$U, tensor_execution(tensorflow, graph, auto), tensor_execution(_, M, D), write(answer(M-D)), nl" 2>&1 | grep -a 'running on cpu' | grep -ac tensorflow)-$(q "tensor_execution(tensorflow, graph, auto), tensor_execution(_, M, D), write(answer(M-D)), nl")" "0-graph-$(q "tensor_execution(tensorflow, graph, auto), tensor_execution(_, _, D), write(answer(D)), nl")"
check "and the same three arguments on torch" "$(timeout 300 "$C" query "$U, tensor_execution(torch, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl" 2>&1 | grep -a 'running on cpu' | grep -ac torch)-$(q "tensor_execution(torch, eager, cuda), tensor_execution(B, M, D), write(answer(B-M-D)), nl")" "$( [ "$(q "torch_cuda_available(A), write(answer(A)), nl")" = true ] && echo "0-torch-eager-cuda" || echo "1-torch-eager-cpu" )"
check "a gradient twice of one loss is the same gradient" "$(q "$E, tensor_from_list([[1.5], [-2.0]], W0), tensor_parameter(W0, W), tensor_binary(mul, W, W, P), tensor_agg(sum, P, L), tensor_grad(L, [W], [G1]), tensor_grad(L, [W], [G2]), tensor_to_list(G1, L1), tensor_to_list(G2, L2), (L1 == L2 -> write(answer(same)) ; write(answer(different))), nl")" "same"

echo
echo "-- tutorial 31's fit, the same program on the other library, identical across its two paths"
T31="$ROOT/tutorials/tensor/31-tensor-expressions.pl"
if [ -f "$T31" ]; then
  tfout=$(timeout 600 "$C" --kb tutorials --embed "$(mktemp -d)" run "$T31" "tensor_execution(tensorflow, graph), train" 2>/dev/null)
  tf=$(echo "$tfout" | grep -a '^graph: loss')
  to=$(timeout 600 "$C" --kb tutorials --embed "$(mktemp -d)" run "$T31" "tensor_execution(torch, graph), train" 2>/dev/null | grep -a '^graph: loss')
  echo "     tensorflow: $tf"; echo "     torch:      $to"
  check "eager and graph on tensorflow, identical" "$(echo "$tfout" | grep -ac '^identical')" "1"
  tw=$(echo "$tf" | grep -aoE 'w \[[^]]*\]' | tr -d 'w []'); ow=$(echo "$to" | grep -aoE 'w \[[^]]*\]' | tr -d 'w []')
  if [ -z "$tw" ]; then d=missing; else d=$(maxdiff "$tw/$ow"); fi
  # two libraries' float32, two hundred steps apart: 1e-2, not the 1e-5 of one op
  check "the weights agree within 1e-2" "$(awk -v d="$d" 'BEGIN { print (d <= 1e-2) ? "within 1e-2" : "off by " d }')" "within 1e-2"
fi
echo
if [ "$failures" -eq 0 ]; then echo "GREEN: 0 failure(s)"; else echo "RED: $failures failure(s)"; exit 1; fi
