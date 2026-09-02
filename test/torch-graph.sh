#!/bin/sh
# library(torch)'s GRAPH execution path, held to EQUALITY against eager.
#
#   sh test/torch-graph.sh            the predicates, and six tutorials
#   ALL=1 sh test/torch-graph.sh      the predicates, and all 28 tutorials
#
# THE RULE UNDER TEST is DESIGN-lazy-graph.md's first sentence: a program
# written for the eager path runs unchanged under torch_execution(graph) --
# same predicates, same answers. So nearly every check here runs ONE goal
# twice, in two fresh processes, one per mode, and demands that the two
# answers be EQUAL, not close. That is possible because the graph path
# forces through the very raw workers eager calls, on the same CPU, and
# because stochastic leaves execute at record time, so `torch_seed' draws
# the same numbers in the same order under both.
#
# The rest checks what eager cannot do and the graph path must: know a
# shape without executing, raise a shape error at the same goal, skip work
# a failed branch asked for, survive tensor_free of an input, and say all
# of that in tensor_graph_stats/1.
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
if ! timeout 20 "$C" query "use_module(library(torch)), torch_execution(M), write(M), nl" 2>/dev/null \
     | grep -aq '^eager$'; then
  echo "SKIP (library(torch) will not load, or has no graph path)"
  exit 0
fi
U="use_module(library(torch))"
q() { timeout 120 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
# the same, with the engine's variable names normalised: a goal one call
# longer numbers its variables differently, and an error term carries them
qn() { q "$1" | sed -E 's/_G[0-9]+/_/g'; }
# the same goal under both modes, in two fresh processes; equal or FAIL
both() {
  e=$(q "torch_execution(eager), torch_seed(11), $2")
  g=$(q "torch_execution(graph), torch_seed(11), $2")
  check "$1" "$g" "$e"
}
# the leaves every check below starts from
LEAVES="tensor_new([2,3], randn, A), tensor_new([3,2], randn, B), tensor_new([2,3], randn, A2)"

echo "-- the switch"
check "eager is the default" "$(q "torch_execution(M), write(answer(M)), nl")" "eager"
check "graph, once asked for, is what it answers" \
  "$(q "torch_execution(graph), torch_execution(M), write(answer(M)), nl")" "graph"
check "an unknown mode is a domain error" \
  "$(q "catch(torch_execution(fast), error(E, _), true), write(answer(E)), nl")" \
  "domain_error(torch_execution,fast)"

echo
echo "-- every producer, equal to eager"
for op in neg abs exp log sqrt relu sigmoid tanh transpose; do
  both "unary $op" "$LEAVES, tensor_unary($op, A, R), tensor_to_list(R, L), write(answer(L)), nl"
done
for op in add sub mul div pow; do
  both "scalar $op" "$LEAVES, tensor_scalar($op, A, 2.5, R), tensor_to_list(R, L), write(answer(L)), nl"
done
for op in add sub mul div; do
  both "binary $op" "$LEAVES, tensor_binary($op, A, A2, R), tensor_to_list(R, L), write(answer(L)), nl"
done
both "binary matmul" "$LEAVES, tensor_binary(matmul, A, B, R), tensor_to_list(R, L), write(answer(L)), nl"
both "argmax" "$LEAVES, tensor_argmax(A, 1, R), tensor_to_list(R, L), write(answer(L)), nl"
both "reshape" "$LEAVES, tensor_reshape(A, [3,2], R), tensor_to_list(R, L), write(answer(L)), nl"
both "cat" "$LEAVES, tensor_cat([A, A2], 0, R), tensor_to_list(R, L), write(answer(L)), nl"
both "index_rows" "$LEAVES, tensor_from_list([1, 0, 1], I), tensor_index_rows(A, I, R), tensor_to_list(R, L), write(answer(L)), nl"
both "rows" "$LEAVES, tensor_rows(A, 1, 2, R), tensor_to_list(R, L), write(answer(L)), nl"
both "cols" "$LEAVES, tensor_cols(A, 0, 2, R), tensor_to_list(R, L), write(answer(L)), nl"
both "standardise" "$LEAVES, tensor_standardise(A, 2, R), tensor_to_list(R, L), write(answer(L)), nl"
both "zeros" "tensor_zeros([2,2], R), tensor_to_list(R, L), write(answer(L)), nl"
both "ones" "tensor_ones([1,3], R), tensor_to_list(R, L), write(answer(L)), nl"
both "full" "tensor_full([2,2], 3.5, R), tensor_to_list(R, L), write(answer(L)), nl"
both "eye" "tensor_eye(3, R), tensor_to_list(R, L), write(answer(L)), nl"
both "arange" "tensor_arange(5, R), tensor_to_list(R, L), write(answer(L)), nl"
both "randn, rand and randperm draw in program order" \
  "tensor_randn([2], A), tensor_rand([2], B), tensor_randperm(4, P), tensor_to_list(A, LA), tensor_to_list(B, LB), tensor_to_list(P, LP), write(answer(LA-LB-LP)), nl"
both "reduce, sum through a deferred chain" \
  "$LEAVES, tensor_scalar(mul, A, 2.0, X), tensor_unary(relu, X, Y), tensor_reduce(sum, Y, S), write(answer(S)), nl"
both "item, through a deferred chain" \
  "tensor_full([1], 2.0, A), tensor_scalar(pow, A, 3.0, B), tensor_item(B, V), write(answer(V)), nl"
both "shape of a deferred result" \
  "$LEAVES, tensor_binary(matmul, A, B, R), tensor_shape(R, S), write(answer(S)), nl"
both "an eleven-op expression" \
  "$LEAVES, tensor_scalar(mul, A, 2.0, X1), tensor_unary(relu, X1, X2), tensor_unary(transpose, X2, X3), tensor_binary(matmul, A, X3, X4), tensor_unary(abs, X4, X4a), tensor_scalar(add, X4a, 1.0, X5), tensor_unary(sqrt, X5, X6), tensor_binary(sub, X6, X4, X7), tensor_unary(abs, X7, X8), tensor_reshape(X8, [4], X9), tensor_reduce(mean, X9, M), tensor_to_list(X9, L), write(answer(M-L)), nl"
both "model_train forces its data, then trains the same" \
  "torch_seed(3), tensor_new([64, 3], randn, X0), tensor_scalar(mul, X0, 2.0, X), tensor_cols(X, 0, 1, Y0), tensor_scalar(add, Y0, 0.5, Y), model_new([input(3), dense(8, relu), dense(1)], M), model_train(M, X, Y, [epochs(5), batch(16), lr(0.01), final_loss(Loss)]), model_predict(M, X, P), tensor_shape(P, S), write(answer(S-Loss)), nl"

echo
echo "-- what the graph path knows without executing, and says"
G="torch_execution(graph)"
check "a shape is known with nothing executed" \
  "$(q "$G, tensor_zeros([3,4], A), tensor_ones([4,5], B), tensor_binary(matmul, A, B, C), tensor_shape(C, S), tensor_graph_stats(stats(_, executed(X), _, pending(P))), write(answer(S-X-P)), nl")" \
  "[3,5]-0-3"
check "a shape error is raised at the goal, as eager raises it" \
  "$(qn "$G, tensor_zeros([3,4], A), tensor_ones([5,6], B), catch(tensor_binary(matmul, A, B, _), error(E, _), true), write(answer(E)), nl")" \
  "$(qn "tensor_zeros([3,4], A), tensor_ones([5,6], B), catch(tensor_binary(matmul, A, B, _), error(E, _), true), write(answer(E)), nl")"
check "standardise past the rows: the same error, at the goal" \
  "$(qn "$G, tensor_zeros([2,3], A), catch(tensor_standardise(A, 5, _), error(E, _), true), write(answer(E)), nl")" \
  "$(qn "tensor_zeros([2,3], A), catch(tensor_standardise(A, 5, _), error(E, _), true), write(answer(E)), nl")"
check "a second read executes nothing new" \
  "$(q "$G, tensor_zeros([2,2], A), tensor_scalar(add, A, 1.0, B), tensor_unary(exp, B, C), tensor_to_list(C, _), tensor_to_list(C, _), tensor_reduce(sum, C, _), tensor_graph_stats(stats(recorded(R), executed(X), _, _)), write(answer(R-X)), nl")" \
  "3-3"
check "work asked for on a failed branch never happens" \
  "$(q "$G, tensor_zeros([2,2], A), ( tensor_scalar(mul, A, 2.0, _), tensor_unary(exp, A, _), fail ; true ), tensor_graph_stats(stats(recorded(R), executed(X), _, pending(P))), write(answer(R-X-P)), nl")" \
  "3-0-3"
check "tensor_force executes what a handle depends on" \
  "$(q "$G, tensor_zeros([2,2], A), tensor_scalar(mul, A, 2.0, B), tensor_unary(exp, B, C), tensor_force(C), tensor_graph_stats(stats(_, executed(X), _, pending(P))), write(answer(X-P)), nl")" \
  "3-0"
both "tensor_free of an input leaves the dependant its own value" \
  "tensor_zeros([2,2], A), tensor_scalar(add, A, 1.0, B), tensor_free(A), tensor_zeros([2,2], C), tensor_scalar(add, C, 5.0, D), tensor_to_list(D, _), tensor_to_list(B, L), write(answer(L)), nl"
both "randn leaves forced in reverse order still hold their draws" \
  "tensor_randn([2], A), tensor_randn([2], B), tensor_scalar(mul, B, 1.0, B2), tensor_scalar(mul, A, 1.0, A2), tensor_to_list(B2, LB), tensor_to_list(A2, LA), write(answer(LA-LB)), nl"
check "a freed handle is not a tensor, in either mode" \
  "$(q "$G, tensor_zeros([2], A), tensor_free(A), catch(tensor_to_list(A, _), error(E, _), true), write(answer(E)), nl")" \
  "$(q "tensor_zeros([2], A), tensor_free(A), catch(tensor_to_list(A, _), error(E, _), true), write(answer(E)), nl")"

echo
echo "-- the tutorials: the same program, the same printed result"
# Each tutorial's `train' goal, run under eager and under graph against fresh
# stores, its whole stdout compared. The training loop is C++ in both modes
# and only the data preparation is deferred, so the outputs must be equal.
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-torch-graph-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM
if [ "${ALL:-0}" = 1 ]; then
  TUTS=$(ls "$ROOT"/tutorials/torch/[0-9]*.pl)
else
  # 30 is the tutorial ABOUT the two paths, and 31 is 30 again as expressions: their
  # train runs both paths itself and refuses to save unless they agree, so under
  # either prefix each prints the same lines
  TUTS="$ROOT/tutorials/torch/01-linear-regression.pl $ROOT/tutorials/torch/04-sine-approximation.pl
        $ROOT/tutorials/torch/07-xor.pl $ROOT/tutorials/torch/14-autoencoder.pl $ROOT/tutorials/torch/20-save-load.pl
        $ROOT/tutorials/torch/30-two-paths.pl $ROOT/tutorials/torch/31-tensor-expressions.pl"
fi
for pl in $TUTS; do
  name=$(basename "$pl" .pl)
  e=$(timeout 1200 "$C" --kb tutorials --embed "$OUT/eager-$name" run "$pl" "torch_execution(eager), train" 2>&1 | tr -d '\r')
  g=$(timeout 1200 "$C" --kb tutorials --embed "$OUT/graph-$name" run "$pl" "torch_execution(graph), train" 2>&1 | tr -d '\r')
  check "tutorial $name" "$(echo "$g" | tail -3 | tr '\n' ' ')" "$(echo "$e" | tail -3 | tr '\n' ' ')"
done

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"; exit 1
fi
