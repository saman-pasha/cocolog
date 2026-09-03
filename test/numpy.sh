#!/bin/sh
# library(numpy): numpy arrays as cocolog predicates, over numpy's C API.
#
# WHAT IS BEING PINNED, in the order the module's header lists it:
#
#   THE ARRAY IS numpy's. A list of lists becomes a matrix with the shape,
#   dtype and elements it says; a reduction answers a number, an operation
#   an array; the dtypes survive np_array and np_astype.
#
#   THE FILE IS numpy's FORMAT, written and read here in C. An array saved
#   by np_save loads back equal; where a python3 with numpy is on the
#   path, numpy.load reads what np_save wrote and np_load reads what
#   numpy.save wrote -- an int64 array, and one in Fortran order. The CSV
#   round trip holds to the digit.
#
#   THE KNOWLEDGE BASE KEEPS IT ACROSS PROCESSES, dtype and shape and all:
#   np_store in one process, np_fetch in another, against the embedded
#   store -- and against a Zigurat server when one answers, where the
#   numbers travel as rows of the tensors table and no chunk clause is
#   written. A second store under the same name replaces the first;
#   np_forget leaves nothing behind.
#
#   NOTHING LEAKS: every handle a section makes is freed, and np_handles
#   answers 0 at the end.
#
#   sh test/numpy.sh
#
# SKIPs without library/numpy.so (sh modules/numpy/build.sh says what it
# needs: a python3 with numpy and a shared libpython).

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"
[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }
[ -f "$ROOT/library/numpy.so" ] || { echo "SKIP (no library/numpy.so -- sh modules/numpy/build.sh)"; exit 0; }
if ! timeout 60 "$C" --local query "use_module(library(numpy)), np_zeros([1], A), np_free(A), write(ok), nl" 2>/dev/null | grep -aq '^ok$'; then
  echo "SKIP (library(numpy) does not start: is the python3 it was built against still here?)"
  exit 0
fi

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-62s %s\n' "$1" "$(echo "$2" | cut -c1-40)"
  else
    printf 'FAIL %-62s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}
answer() { grep -aoE 'answer\(.*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
U="use_module(library(numpy))"
q() { timeout 120 "$C" --local query "$U, $1" 2>&1 | answer; }

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-numpy-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

echo "-- the array is numpy's"
check "a list of lists is a 2 by 3 float64 matrix" \
  "$(q "np_from_list([[1.0,2.0,3.0],[4.0,5.0,6.0]], A), np_shape(A, S), np_dtype(A, T), np_size(A, N), np_free(A), write(answer(S-T-N)), nl")" \
  "[2,3]-float64-6"
check "and reads back as the list it came from" \
  "$(q "np_from_list([[1.0,2.0],[3.0,4.0]], A), np_to_list(A, L), np_free(A), write(answer(L)), nl")" \
  "[[1.0,2.0],[3.0,4.0]]"
check "np_array keeps the dtype it is given, np_astype changes it" \
  "$(q "np_array([1,2,3], int32, A), np_dtype(A, T1), np_astype(A, float32, B), np_dtype(B, T2), np_to_list(B, L), np_free(A), np_free(B), write(answer(T1-T2-L)), nl")" \
  "int32-float32-[1.0,2.0,3.0]"
check "sum, mean, max and argmax are numbers" \
  "$(q "np_from_list([[1.0,5.0],[3.0,4.0]], A), np_sum(A, S), np_mean(A, M), np_max(A, X), np_argmax(A, I), np_free(A), write(answer(S-M-X-I)), nl")" \
  "13.0-3.25-5.0-1"
check "a reduction along an axis is an array" \
  "$(q "np_from_list([[1.0,2.0],[3.0,4.0]], A), np_reduce(sum, A, 0, C), np_to_list(C, L), np_free(A), np_free(C), write(answer(L)), nl")" \
  "[4.0,6.0]"
check "matmul, and a scalar on the right" \
  "$(q "np_from_list([[1.0,2.0],[3.0,4.0]], A), np_matmul(A, A, B), np_to_list(B, LB), np_scalar(mul, A, 10, C), np_get(C, [1,0], G), np_free(A), np_free(B), np_free(C), write(answer(LB-G)), nl")" \
  "[[7.0,10.0],[15.0,22.0]]-30.0"
check "the elementwise math over libm: sqrt, and relu" \
  "$(q "np_from_list([-4.0,0.0,9.0], A), np_unary(relu, A, R), np_to_list(R, LR), np_from_list([4.0,9.0], B), np_sqrt(B, Q), np_to_list(Q, LQ), np_free(A), np_free(R), np_free(B), np_free(Q), write(answer(LR-LQ)), nl")" \
  "[0.0,0.0,9.0]-[2.0,3.0]"
check "eye, transpose, reshape, rows, cols, concat, sort" \
  "$(q "np_eye(2, E), np_arange(0.0, 6.0, 1.0, R), np_reshape(R, [2,3], M), np_transpose(M, T), np_shape(T, ST), np_rows(M, 1, 2, Row), np_to_list(Row, LRow), np_cols(M, 1, 3, Col), np_shape(Col, SC), np_concat([E, E], 0, Cat), np_shape(Cat, SCat), np_from_list([3.0,1.0,2.0], U), np_sort(U, So), np_to_list(So, LSo), np_free(E), np_free(R), np_free(M), np_free(T), np_free(Row), np_free(Col), np_free(Cat), np_free(U), np_free(So), write(answer(ST-LRow-SC-SCat-LSo)), nl")" \
  "[3,2]-[[3.0,4.0,5.0]]-[2,2]-[4,2]-[1.0,2.0,3.0]"
check "a comparison is a bool array, and where chooses by it" \
  "$(q "np_from_list([1.0,5.0,3.0], A), np_from_list([2.0,2.0,2.0], B), np_binary(gt, A, B, C), np_dtype(C, T), np_where(C, A, B, W), np_to_list(W, L), np_free(A), np_free(B), np_free(C), np_free(W), write(answer(T-L)), nl")" \
  "bool-[2.0,5.0,3.0]"
check "np_set is the one mutation, and np_seed repeats the draws" \
  "$(q "np_zeros([2,2], A), np_set(A, [0,1], 7.5), np_get(A, [0,1], V), np_seed(11), np_rand([3], R1), np_to_list(R1, L1), np_seed(11), np_rand([3], R2), np_to_list(R2, L2), ( L1 == L2 -> Same = same ; Same = differ ), np_free(A), np_free(R1), np_free(R2), write(answer(V-Same)), nl")" \
  "7.5-same"
check "an index off the array is an error, not a crash" \
  "$(q "np_zeros([2], A), catch(np_get(A, [5], _), error(E, _), true), np_free(A), functor(E, F, _), write(answer(F)), nl")" \
  "cocolog_error"

echo
echo "-- the file is numpy's format, in C"
check ".npy: save, load, equal, int64 kept" \
  "$(q "np_array([[1,2,3],[4,5,6]], int64, A), np_save('$OUT/a.npy', A), np_load('$OUT/a.npy', B), np_dtype(B, T), np_to_list(B, L), np_free(A), np_free(B), write(answer(T-L)), nl")" \
  "int64-[[1,2,3],[4,5,6]]"
check ".csv: save and load to the digit, %.17g both ways" \
  "$(q "np_from_list([[0.1,0.2],[1.0e-9,12345.678]], A), np_save_csv('$OUT/a.csv', A), np_load_csv('$OUT/a.csv', B), np_to_list(A, LA), np_to_list(B, LB), ( LA == LB -> R = same ; R = LA-LB ), np_free(A), np_free(B), write(answer(R)), nl")" \
  "same"
if command -v python3 >/dev/null 2>&1 && python3 -c 'import numpy' >/dev/null 2>&1; then
  check "numpy.load reads what np_save wrote" \
    "$(python3 -c "import numpy; a = numpy.load('$OUT/a.npy'); print(str(a.dtype) + '-' + str(a.tolist()).replace(' ', ''))")" \
    "int64-[[1,2,3],[4,5,6]]"
  python3 -c "import numpy; numpy.save('$OUT/t.npy', numpy.arange(6, dtype='float32').reshape(2,3)); numpy.save('$OUT/f.npy', numpy.asfortranarray(numpy.arange(6.0).reshape(2,3)))"
  check "np_load reads what numpy.save wrote: float32, and Fortran order" \
    "$(q "np_load('$OUT/t.npy', A), np_dtype(A, T), np_to_list(A, L), np_load('$OUT/f.npy', F), np_to_list(F, LF), np_free(A), np_free(F), write(answer(T-L-LF)), nl")" \
    "float32-[[0.0,1.0,2.0],[3.0,4.0,5.0]]-[[0.0,1.0,2.0],[3.0,4.0,5.0]]"
else
  echo "     (no python3 with numpy on the path: the cross-check with numpy.load not run)"
fi

echo
echo "-- the knowledge base keeps it across processes"
printf ':- use_module(library(numpy)).\n' > "$OUT/p.pl"
E() { timeout 120 "$C" --kb numpy_case --embed "$OUT/store" run "$OUT/p.pl" "$1" 2>&1 | answer; }
check "embed: stored in one process" \
  "$(E "np_array([[1,2,3],[4,5,6]], int32, A), np_store(m, A), np_stored(N), np_free(A), write(answer(N)), nl")" \
  "m"
check "embed: fetched in another, dtype and shape and all" \
  "$(E "np_fetch(m, B), np_dtype(B, T), np_shape(B, S), np_to_list(B, L), np_free(B), write(answer(T-S-L)), nl")" \
  "int32-[2,3]-[[1,2,3],[4,5,6]]"
check "embed: a second store under the name replaces it; forget leaves nothing" \
  "$(E "np_linspace(0.0, 1.0, 5, A), np_store(m, A), np_fetch(m, B), np_to_list(B, L), np_forget(m), ( np_stored(_) -> R = still ; R = gone ), np_free(A), np_free(B), write(answer(L-R)), nl")" \
  "[0.0,0.25,0.5,0.75,1.0]-gone"

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
if timeout 20 "$C" --host "$HOST" --tcp "$PORT" --timeout 10 --kb numpy_case list >/dev/null 2>&1; then
  W() { timeout 120 "$C" --kb numpy_case --host "$HOST" --tcp "$PORT" --timeout 60 query "$U, $1" 2>&1 | answer; }
  timeout 60 "$C" --kb numpy_case --host "$HOST" --tcp "$PORT" --timeout 60 forget >/dev/null 2>&1
  check "wire: 2100 numbers stored as rows, their sum in this process" \
    "$(W "np_seed(3), np_randn([3,700], A), np_store(big, A), np_sum(A, S), np_free(A), write(answer(S)), nl" | cut -c1-12)" \
    "$(W "np_seed(3), np_randn([3,700], A), np_sum(A, S), np_free(A), write(answer(S)), nl" | cut -c1-12)"
  check "wire: the same sum from another process, and no chunk clause" \
    "$(W "np_fetch(big, B), np_shape(B, Sh), np_sum(B, S), findall(Q, np_chunk(big, Q, _), Qs), length(Qs, NC), np_free(B), write(answer(Sh-NC)), nl")" \
    "[3,700]-0"
  timeout 60 "$C" --kb numpy_case --host "$HOST" --tcp "$PORT" --timeout 60 forget >/dev/null 2>&1
else
  echo "     (no Zigurat server at $HOST:$PORT -- the wire half not run)"
fi

echo
echo "-- nothing leaks"
check "every handle above was freed: a fresh process ends at 0 after a round" \
  "$(q "np_zeros([3,3], A), np_ones([3,3], B), np_add(A, B, C), np_free(A), np_free(B), np_free(C), np_handles(N), write(answer(N)), nl")" \
  "0"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $failures failure(s)"; exit 1
fi
