#!/bin/sh
# The whole story in one test: a Prolog program locates a dataset with
# the Files module, loads and trains on it with the Torch module, and
# stores the trained model in Zigurat through an assert -- then a
# SECOND process loads the model back out of the store and reproduces
# the first one's predictions exactly.
#
# It SKIPS without a `make full' build, because "no libtorch here" and
# "the module is wrong" are different findings.

set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog-full"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-torch-XXXXXX")
STORE="$OUT/store"
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog-full built (make full needs libtorch and a ZiguratIP checkout)"
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
sed -i "s|'CSVFILE'|'$OUT/data.csv'|" "$OUT/train.pl"

cat > "$OUT/load.pl" <<'PL'
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
train_out=$(timeout 300 "$COCOLOG" --kb torch_test --store "$STORE" run "$OUT/train.pl" train_main 2>&1)
echo "$train_out" | sed 's/^/     /'
check "the program trained and saved" \
  "$(echo "$train_out" | grep -c '^saved$')" "1"

echo "a fresh process loads it back"
load_out=$(timeout 120 "$COCOLOG" --kb torch_test --store "$STORE" run "$OUT/load.pl" load_main 2>&1)
echo "$load_out" | sed 's/^/     /'
check "the model came back out of the store" \
  "$(echo "$load_out" | grep -c '^reloaded$')" "1"
check "with its architecture intact" \
  "$(echo "$load_out" | grep -c 'input(3),dense(24,relu),dense(1')" "1"
check "and the stored weights predict identically" \
  "$(echo "$load_out" | grep -c '^predictions_agree$')" "1"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
