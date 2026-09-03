#!/bin/sh
# Tensors as a table of one vector field: model parameters in
# cocolog::tensors -- doubles in Vector<Double> rows, each row's id
# columns (kb, name) saying WHICH tensor and `seq' which piece -- with
# clause chunks kept as the fallback for the arrangements that have no
# tensor storage.
#
# WHAT IT IS CHECKING:
#
#   THE WIRE ARRANGEMENT USES THE TABLE. After model_save over the
#   binary protocol, torch_params/3 answers false -- the parameters are
#   rows, not clauses -- while torch_model/2 (the spec, the name the
#   accumulator-style pollers ask for) is still a clause. model_load in
#   a SECOND process gets the model back whole: 100% on the corners.
#
#   AND THE TUTORIAL IT DRIVES NO LONGER CALLS model_save/2, which is
#   why the two claims above are made about a model of this case's own.
#   Every tensor lesson from 1 to 30 was rewritten in
#   library(tensor_expr), so 07-xor saves with params_save/2 -- and
#   that is arrangement-independent by design: it writes
#   '$te_param'(Name, I, Shape) and '$te_chunk'(Name, I, Seq, Chunk) as
#   ordinary clauses and never reaches for the tensors table. So the
#   tutorial proves the ROUND TRIP, in every arrangement, and a
#   model_save/2 beside it proves the TABLE. Asked about the tutorial's
#   name instead, torch_model/2 was empty -- a red -- and torch_params/3
#   answered false for the wrong reason, which is the worse of the two.
#
#   HTTP READS IT PAGED. The tensor page takes `from' and `limit', so a
#   tensor of any number of rows streams a piece per request -- the way
#   anything over HTTP should face a table that can hold a huge number
#   of rows -- and the elements travel as the IEEE bits of the double,
#   because the default decimal rendering keeps six digits and a model
#   weight does not survive that. A 1994-parameter model makes four
#   512-double pieces and loads back over --http exactly.
#
#   THE EMBEDDED ARRANGEMENT FALLS BACK. Its engine's columns are int64
#   and text, so the tensor hooks stay null there and model_save keeps
#   parameters in clause chunks -- torch_params answers -- and
#   model_load still works. --local is the same fallback and the
#   tutorials hold it.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-tensors-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s\n' "$1"
  else
    printf 'FAIL %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$ROOT/cocolog" ]; then
  echo "SKIP (no cocolog; make)"
  exit 0
fi
C="$ROOT/cocolog"
# library(torch) IS A LOADABLE MODULE NOW, under modules/torch. The tutorial
# this drives carries its own directive; the bare queries below need one too.
. "$HERE/library-path.sh"
T="use_module(library(torch))"
# "no torch here" and "the backend is wrong" are different findings -- the
# same rule the database suites follow. Every check below drives the
# xor tutorial through library(torch), so without the module the case
# has no subject.
if [ ! -f "$ROOT/library/torch.so" ]; then
  echo "SKIP (no library/torch.so -- sh modules/torch/build.sh against libtorch)"
  exit 0
fi
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
ZEYTUN=${ZEYTUN_PORT:-2190}
KB=tensors_test
W="--kb $KB --host $HOST --tcp $PORT --timeout 30"

if ! timeout 20 "$C" $W list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi
timeout 60 "$C" $W forget >/dev/null 2>&1

# ---- wire: the tutorial's clauses, and the table --------------------

timeout 300 "$C" $W run "$ROOT/tutorials/tensor/07-xor.pl" train > "$OUT/train.log" 2>&1
got=$(grep -c '^saved$' "$OUT/train.log")
check "a model trains and saves over the wire" "$got" "1"

# FOUR ROWS BECAUSE THE XOR MODEL IS TWO DENSE LAYERS, a weight and a
# bias each; params_save/2 writes one '$te_param'(Name, I, Shape) per
# tensor and chunks the values into '$te_chunk'/4 beside it. Pinned
# rather than "some": a shape row that stopped appearing would leave
# params_load/2 throwing existence_error, and "more than none" would
# not notice three of the four going missing.
got=$(timeout 60 "$C" $W query "$T, '\$te_param'(t07_xor, _, _)" 2>/dev/null | tail -1)
check "the tutorial's parameters are params_save/2's clauses" "$got" "4 answer(s)."

got=$(timeout 300 "$C" $W run "$ROOT/tutorials/tensor/07-xor.pl" test 2>/dev/null | tail -1)
check "a second process loads it back whole" "$got" "ok"

# THE TABLE, ASKED ABOUT THE PREDICATE THAT USES IT. `big' is also what
# the --http checks below page through, so it is made once, here.
timeout 120 "$C" $W query "$T, torch_seed(1), model_new([input(20), dense(64, relu), dense(10, log_softmax)], M), model_save(big, M)" >/dev/null 2>&1

got=$(timeout 60 "$C" $W query "$T, torch_params(big, _, _)" 2>/dev/null | tail -1)
check "the parameters are rows, not chunk clauses" "$got" "false."

got=$(timeout 60 "$C" $W --answers 1 query "$T, torch_model(big, _)" 2>/dev/null | grep -c '^  1\.')
check "the spec is still the clause pollers ask for" "$got" "1"

# ---- http: paged, and exact -----------------------------------------

got=$(timeout 300 "$C" --kb $KB --host "$HOST" --http "$ZEYTUN" \
        run "$ROOT/tutorials/tensor/07-xor.pl" test 2>/dev/null | tail -1)
check "model_load works over --http" "$got" "ok"

got=$(timeout 30 "$C" --kb $KB --host "$HOST" --http "$ZEYTUN" \
        query "$T, model_load(big, M), model_params(M, P), length(P, N), N == 1994" 2>/dev/null | grep -c '^  1\.')
check "a four-piece tensor loads over --http, all 1994" "$got" "1"

if command -v curl >/dev/null 2>&1; then
  got=$(curl -s "http://$HOST:$ZEYTUN/cocolog/tensor.zt?kb=$KB&name=big&from=0&limit=1" \
        | sed -n '2p')
  check "the page is paged: T says four pieces" "$got" "T 4"
  got=$(curl -s "http://$HOST:$ZEYTUN/cocolog/tensor.zt?kb=$KB&name=big&from=0&limit=1" \
        | sed -n '3p')
  check "and limit=1 carries only the piece asked for" "$got" "V 0 512"
else
  echo "curl: SKIP (page shape unchecked)"
fi

# ---- embed: the same rows, in-process -------------------------------
# The engine's VECTOR column kind carries the tensors table inside the
# one binary, so the embedded arrangement stores parameters exactly as
# the server does: rows, not clause chunks. The same split as over the
# wire -- the tutorial's params_save/2 clauses, then a model_save/2 of
# this case's own for the table.

timeout 300 "$C" --embed "$OUT/store" --kb $KB run "$ROOT/tutorials/tensor/07-xor.pl" train \
  > "$OUT/etrain.log" 2>&1
got=$(timeout 60 "$C" --embed "$OUT/store" --kb $KB \
        query "$T, '\$te_param'(t07_xor, _, _)" 2>/dev/null | tail -1)
check "embedded: the same four shape rows" "$got" "4 answer(s)."
got=$(timeout 300 "$C" --embed "$OUT/store" --kb $KB \
        run "$ROOT/tutorials/tensor/07-xor.pl" test 2>/dev/null | tail -1)
check "and a second process loads them back whole" "$got" "ok"

timeout 120 "$C" --embed "$OUT/store" --kb $KB \
  query "$T, torch_seed(1), model_new([input(4), dense(8, relu), dense(2, log_softmax)], M), model_save(esmall, M)" \
  >/dev/null 2>&1
got=$(timeout 60 "$C" --embed "$OUT/store" --kb $KB \
        query "$T, torch_params(esmall, _, _)" 2>/dev/null | tail -1)
check "embedded: the parameters are rows, not clauses" "$got" "false."
got=$(timeout 60 "$C" --embed "$OUT/store" --kb $KB --answers 1 \
        query "$T, torch_model(esmall, _)" 2>/dev/null | grep -c '^  1\.')
check "embedded: and the spec is still a clause" "$got" "1"

timeout 60 "$C" $W forget >/dev/null 2>&1

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
