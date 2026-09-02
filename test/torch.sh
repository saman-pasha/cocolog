#!/bin/sh
# The whole story in one test: a Prolog program locates a dataset with
# the Files module, loads and trains on it with the Torch module, and
# stores the trained model in Zigurat through an assert -- then a
# SECOND process loads the model back out of the store and reproduces
# the first one's predictions exactly.
#
# It SKIPS when the binary lacks the torch module, because "no libtorch here" and
# "the module is wrong" are different findings.

set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
# library(torch) IS A LOADABLE MODULE NOW, under modules/torch, so this
# needs torch.so on the library path rather than an object in the binary.
. "$HERE/library-path.sh"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-torch-XXXXXX")
STORE="$OUT/store"
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built (make needs libtorch and a built ZiguratIP checkout)"
  exit 0
fi

# ---- the dataset: y = 3*x1 - 2*x2 + 0.5*x3 + 1, with a little noise --
awk 'BEGIN {
  srand(42);
  for (i = 0; i < 240; i++) {
    x1 = rand()*2-1; x2 = rand()*2-1; x3 = rand()*2-1;
    y = 3*x1 - 2*x2 + 0.5*x3 + 1 + (rand()-0.5)*0.05;
    printf "%.6f,%.6f,%.6f,%.6f\n", x1, x2, x3, y;
  }
}' > "$OUT/data.csv"

cat > "$OUT/train.pl" <<'PL'
:- use_module(library(torch)).
train_main :-
    % the Files module finds and vouches for the dataset
    getenv_path(CSV),
    ( exists_file(CSV) -> true ; write(no_csv), nl, halt(1) ),
    % the Torch module loads it: [240 rows, 4 cols], features then target
    tensor_load_csv(CSV, All),
    tensor_shape(All, [N, 4]),
    tensor_cols(All, 0, 3, X0),
    tensor_cols(All, 3, 4, Y),
    NTrain is (N * 4) // 5,
    tensor_standardise(X0, NTrain, X),
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    % train
    torch_seed(11),
    model_new([input(3), dense(24, relu), dense(1)], M),
    model_train(M, XTr, YTr, [epochs(150), batch(24), lr(0.01),
                              shuffle(true), final_loss(L)]),
    format("train mse ~4f~n", [L]),
    model_evaluate(M, XTe, YTe, rmse, R),
    format("test rmse ~4f~n", [R]),
    ( R < 0.2 -> true ; write(did_not_learn), nl, halt(1) ),
    % a probe row and its prediction, stored beside the model
    tensor_rows(XTe, 0, 5, Probe),
    tensor_to_list(Probe, ProbeRows),
    model_predict(M, Probe, P),
    tensor_to_list(P, Pred),
    % THE MODEL GOES INTO ZIGURAT: spec and parameters as terms, asserted
    model_save(net1, M),
    assertz(torch_probe(net1, ProbeRows, Pred)),
    write(saved), nl.
getenv_path('CSVFILE').
PL
# the path rides in by substitution -- cocolog has no getenv
# no `sed -i': GNU takes an optional suffix, BSD a mandatory one, and the same
# line means two different things on the two -- on macOS it died here for months
sed "s|'CSVFILE'|'$OUT/data.csv'|" "$OUT/train.pl" > "$OUT/train.pl.new" && mv "$OUT/train.pl.new" "$OUT/train.pl"

cat > "$OUT/load.pl" <<'PL'
:- use_module(library(torch)).
close_enough([], []).
close_enough([[A]|As], [[B]|Bs]) :-
    D is abs(A - B), D < 1.0e-4,
    close_enough(As, Bs).
load_main :-
    % a FRESH PROCESS: the model exists only in the store
    model_load(net1, M),
    torch_probe(net1, ProbeRows, Saved),
    model_spec(M, Spec),
    format("loaded ~w~n", [Spec]),
    % the reloaded model must predict what the trained one predicted
    tensor_from_list(ProbeRows, Probe),
    model_predict(M, Probe, P),
    tensor_to_list(P, Again),
    ( close_enough(Saved, Again)
    ->  write(predictions_agree), nl
    ;   write(predictions_differ), nl, halt(1) ),
    write(reloaded), nl.
PL

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-44s %s\n' "$1" "$2"
  else
    printf 'FAIL %-44s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

echo "training, and storing the model in Zigurat"
train_out=$(timeout 300 "$COCOLOG" --kb torch_test --embed "$STORE" run "$OUT/train.pl" train_main 2>&1)
echo "$train_out" | sed 's/^/     /'
check "the program trained and saved" \
  "$(echo "$train_out" | grep -c '^saved$')" "1"

echo "a fresh process loads it back"
load_out=$(timeout 120 "$COCOLOG" --kb torch_test --embed "$STORE" run "$OUT/load.pl" load_main 2>&1)
echo "$load_out" | sed 's/^/     /'
check "the model came back out of the store" \
  "$(echo "$load_out" | grep -c '^reloaded$')" "1"
check "with its architecture intact" \
  "$(echo "$load_out" | grep -c 'input(3),dense(24,relu),dense(1')" "1"
check "and the stored weights predict identically" \
  "$(echo "$load_out" | grep -c '^predictions_agree$')" "1"

# ---- the wider surface: tensor operations and the conv tier ---------
cat > "$OUT/ops.pl" <<'PL'
:- use_module(library(torch)).
ops_main :-
    tensor_from_list([[1.0,2.0],[3.0,4.0]], A),
    tensor_from_list([[5.0,6.0],[7.0,8.0]], B),
    tensor_matmul(A, B, M), tensor_to_list(M, [[19.0,22.0],[43.0,50.0]]),
    tensor_scalar(pow, A, 2, Sq), tensor_sum(Sq, 30.0),
    tensor_transpose(A, T), tensor_to_list(T, [[1.0,3.0],[2.0,4.0]]),
    tensor_reshape(A, [4], R), tensor_shape(R, [4]),
    tensor_eye(3, E), tensor_sum(E, 3.0),
    tensor_cat([A, B], 1, C), tensor_shape(C, [2,4]),
    tensor_argmax(A, 1, Am), tensor_to_list(Am, [1.0,1.0]),
    write(ops_agree), nl.
PL
awk 'BEGIN { srand(9);
  for (i = 0; i < 120; i++) {
    cls = i % 2; pos = 1 + int(rand()*6);
    for (r = 0; r < 8; r++) for (c = 0; c < 8; c++) {
      v = 0; if (cls == 0 && r == pos) v = 1; if (cls == 1 && c == pos) v = 1;
      printf "%.1f,", v; }
    printf "%d\n", cls; } }' > "$OUT/bars.csv"
cat > "$OUT/conv.pl" <<'PL'
:- use_module(library(torch)).
conv_main :-
    tensor_load_csv('BARS', All),
    tensor_shape(All, [N, 65]),
    tensor_cols(All, 0, 64, X), tensor_cols(All, 64, 65, Y),
    NTrain is (N * 4) // 5,
    tensor_rows(X, 0, NTrain, XTr), tensor_rows(Y, 0, NTrain, YTr),
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    torch_seed(5),
    model_new([image(1,8,8), conv(4,3,relu,pad(1)), norm, pool(2),
               flatten, dropout(0.1), dense(16, relu),
               dense(2, log_softmax)], M),
    model_train(M, XTr, YTr, [epochs(25), batch(12), lr(0.005), loss(nll),
                              shuffle(true), schedule(step, 10, 0.5)]),
    model_evaluate(M, XTe, YTe, accuracy, A),
    ( A >= 0.95 -> true ; write(conv_did_not_learn), nl, halt(1) ),
    model_save(bars, M),
    write(conv_saved), nl.
conv_again :-
    model_load(bars, M2),
    tensor_load_csv('BARS', All),
    tensor_shape(All, [N, 65]),
    tensor_cols(All, 0, 64, X), tensor_cols(All, 64, 65, Y),
    NTrain is (N * 4) // 5,
    tensor_rows(X, NTrain, N, XTe), tensor_rows(Y, NTrain, N, YTe),
    model_evaluate(M2, XTe, YTe, accuracy, A),
    ( A >= 0.95 -> write(conv_reloaded) ; write(conv_buffers_lost) ), nl.
PL
sed "s|'BARS'|'$OUT/bars.csv'|g" "$OUT/conv.pl" > "$OUT/conv.pl.new" && mv "$OUT/conv.pl.new" "$OUT/conv.pl"

echo "the tensor operations"
ops_out=$(timeout 120 "$COCOLOG" --local run "$OUT/ops.pl" ops_main 2>&1)
check "every operation family answers as libtorch does" \
  "$(echo "$ops_out" | grep -c '^ops_agree$')" "1"

echo "a conv net with batch norm, through the store"
conv_out=$(timeout 300 "$COCOLOG" --kb torch_test --embed "$STORE" run "$OUT/conv.pl" conv_main 2>&1)
echo "$conv_out" | sed 's/^/     /'
check "the conv net learned and saved" \
  "$(echo "$conv_out" | grep -c '^conv_saved$')" "1"
conv2_out=$(timeout 120 "$COCOLOG" --kb torch_test --embed "$STORE" run "$OUT/conv.pl" conv_again 2>&1)
echo "$conv2_out" | sed 's/^/     /'
check "and its buffers came back out of Zigurat" \
  "$(echo "$conv2_out" | grep -c '^conv_reloaded$')" "1"

# ---- the device tier: whichever machine this is, the answers hold ---
# On a CUDA box the model trains on the GPU; on a CPU-only box asking
# for cuda is refused with a domain_error rather than silently falling
# back. Either way training after torch_device(auto) must still learn.
cat > "$OUT/device.pl" <<'PL'
:- use_module(library(torch)).
device_main :-
    torch_cuda_available(Avail),
    torch_cuda_count(Count),
    write(cuda(Avail, Count)), nl,
    torch_device(cpu), torch_current_device(cpu),
    ( Avail == true ->
        torch_device(cuda), torch_current_device(cuda(_)),
        catch(torch_device(cuda(Count)),
              error(domain_error(cuda_available, _), _), true)
    ;   catch((torch_device(cuda), write(fell_back_silently), nl, halt(1)),
              error(domain_error(cuda_available, _), _), true),
        catch((torch_device(cuda(0)), write(fell_back_silently), nl, halt(1)),
              error(domain_error(cuda_available, _), _), true)
    ),
    torch_device(auto), torch_current_device(D),
    write(auto_is(D)), nl,
    torch_seed(7),
    model_new([input(2), dense(8, relu), dense(1)], M),
    tensor_from_list([[0.0,0.0],[0.0,1.0],[1.0,0.0],[1.0,1.0]], X),
    tensor_from_list([[0.0],[1.0],[1.0],[2.0]], Y),
    model_train(M, X, Y, [epochs(400), lr(0.05), final_loss(L)]),
    ( L < 0.05 -> write(device_trained) ; write(device_did_not_learn(L)) ), nl,
    model_predict(M, X, P), tensor_shape(P, [4, 1]),
    model_free(M).
PL

echo "the device tier"
dev_out=$(timeout 120 "$COCOLOG" --local run "$OUT/device.pl" device_main 2>&1)
echo "$dev_out" | sed 's/^/     /'
check "cuda is used when present, refused when absent" \
  "$(echo "$dev_out" | grep -c '^auto_is(')" "1"
check "and training on the chosen device learned" \
  "$(echo "$dev_out" | grep -c '^device_trained$')" "1"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
