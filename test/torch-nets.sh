#!/bin/sh
# Twenty-three networks through the Torch module, each a small PyTorch-tutorial
# classic rewritten as a Prolog program: build the data, build the net, train,
# test against a threshold. One process runs all twenty in sequence and the
# knowledge base carries the save/load round trip at the end.
#
# WHAT THE TWENTY COVER, and why each is there:
#
#   regression      1 linreg (sgd)  2 multi_linreg (adam)  3 polyreg
#                   4 sine (tanh approximation)  5 bump (relu approximation)
#                  12 schedule (step lr decay)  13 mae_outliers (mae metric)
#                  16 multiout (two targets at once)
#   classification  6 logistic (bce, sigmoid head)  7 xor  8 moons
#                   9 blobs (four classes, nll) 10 spiral (cross_entropy,
#                     raw logits) 11 dropout (and off at predict time)
#   images         17 cnn_bars (conv/pool/flatten) 18 lenet_mini (two conv
#                     stages) 19 bn_cnn (batch-norm buffers at eval time)
#   autoencoders   14 autoencoder (8->3->8) 15 denoise (noisy in, clean out)
#   persistence    20 roundtrip (model_save / model_load, identical params
#                     and predictions)
#   sequences      21 seq_sum (lstm over plain numbers) 22 seq_contains
#                     (embedding + lstm memory task) 23 seq_roundtrip
#                     (stacked lstm through the store, params identical)
#
# It SKIPs when the binary lacks the torch module, because "no libtorch here" and "the
# module is wrong" are different findings. Data is generated, deterministic
# (torch_seed plus a sin-hash noise), and small enough that the whole suite
# is seconds on a CPU.
#
# THE DEVICE IS A KNOB: COCO_TORCH_DEVICE=auto (the default), cpu, cuda, or
# cuda(N) -- the same twenty nets run wherever the module's device tier
# points, so on a CUDA box
#
#     COCO_TORCH_DEVICE=cuda sh test/torch-nets.sh
#
# is the GPU run. On a box without CUDA the suite also proves the refusal:
# naming cuda must throw domain_error(cuda_available, ...) rather than
# quietly training on the CPU, because those are different results.

set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
# library(torch) IS A LOADABLE MODULE NOW, under modules/torch, so this
# needs torch.so on the library path rather than an object in the binary.
. "$HERE/library-path.sh"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-torch-nets-XXXXXX")
STORE="$OUT/store"
trap 'rm -rf "$OUT"' EXIT INT TERM

if [ ! -x "$COCOLOG" ]; then
  echo "SKIP no cocolog built (make needs libtorch and a built ZiguratIP checkout)"
  exit 0
fi

DEVICE="${COCO_TORCH_DEVICE:-auto}"

cat > "$OUT/nets.pl" <<'PL'
:- use_module(library(torch)).
% ---- shared helpers ---------------------------------------------------------

% Deterministic noise in (-1, 1): the classic sin-hash, so every run of the
% suite sees the same "random" data without a random/1 in the language.
noise(I, R) :-
    S is sin(I * 12.9898) * 43758.5453,
    R is S - truncate(S).

% N points of X evenly over [Lo, Hi], as rows [[X], ...].
xs(N, Lo, Hi, Rows) :-
    N1 is N - 1,
    findall([X], (between(0, N1, I), X is Lo + (Hi - Lo) * I / N1), Rows).

ok(Name, Score) :- format("ok    ~w ~4f~n", [Name, Score]).

% Accuracy the module's way: argmax of the prediction against integer labels.
acc_percent(M, X, Y, P) :-
    model_evaluate(M, X, Y, accuracy, A),
    P is truncate(A * 100 + 0.5).

% Two prediction tensors agree everywhere within epsilon.
rows_close([], []).
rows_close([A|As], [B|Bs]) :- row_close(A, B), rows_close(As, Bs).
row_close([], []).
row_close([A|As], [B|Bs]) :- D is abs(A - B), D < 1.0e-6, row_close(As, Bs).

count_eq([], [], 0).
count_eq([P|Ps], [L|Ls], K) :-
    count_eq(Ps, Ls, K0),
    ( P =:= L -> K is K0 + 1 ; K = K0 ).

% ---- 1: linear regression, sgd ----------------------------------------------
% y = 3x - 2 with a little noise; the first net of every tutorial.
lin_row(I, [X], [Y]) :-
    X is -1 + 2 * I / 63,
    noise(I, E),
    Y is 3 * X - 2 + 0.05 * E.
net_linreg :-
    torch_seed(1),
    findall(R, (between(0, 63, I), lin_row(I, R, _)), XR),
    findall(R, (between(0, 63, I), lin_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(1)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.1), optimiser(sgd)]),
    model_evaluate(M, X, Y, rmse, S),
    S < 0.15, ok(linreg, S),
    model_free(M), tensor_free(X), tensor_free(Y).

% ---- 2: three-feature linear regression, adam -------------------------------
mlin_row(I, [A, B, C], [Y]) :-
    noise(I, A), noise(I + 1000, B), noise(I + 2000, C), noise(I + 3000, E),
    Y is 2 * A - B + 0.5 * C + 1 + 0.05 * E.
net_multi_linreg :-
    torch_seed(2),
    findall(R, (between(0, 119, I), mlin_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), mlin_row(I, _, R)), YR),
    tensor_from_list(XR, X0), tensor_from_list(YR, Y0),
    tensor_train_test(X0, 96, XTr, XTe),
    tensor_train_test(Y0, 96, YTr, YTe),
    model_new([input(3), dense(1)], M),
    model_train(M, XTr, YTr, [epochs(250), batch(24), lr(0.02), optimiser(adam)]),
    model_evaluate(M, XTe, YTe, rmse, S),
    S < 0.15, ok(multi_linreg, S).

% ---- 3: polynomial regression on engineered features ------------------------
% y = x^3 - x, learned linearly over [x, x^2, x^3].
poly_row(I, [X, X2, X3], [Y]) :-
    X is -1 + 2 * I / 99,
    X2 is X * X, X3 is X2 * X,
    Y is X3 - X.
net_polyreg :-
    torch_seed(3),
    findall(R, (between(0, 99, I), poly_row(I, R, _)), XR),
    findall(R, (between(0, 99, I), poly_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(3), dense(1)], M),
    model_train(M, X, Y, [epochs(400), batch(25), lr(0.05), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    S < 0.05, ok(polyreg, S).

% ---- 4: sin(2 pi x) through a tanh hidden layer -----------------------------
sine_row(I, [X], [Y]) :- X is -1 + 2 * I / 159, Y is sin(2 * pi * X).
net_sine :-
    torch_seed(4),
    findall(R, (between(0, 159, I), sine_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), sine_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(48, tanh), dense(1)], M),
    model_train(M, X, Y, [epochs(1200), batch(32), lr(0.01), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    ( S < 0.1 -> true ; format("      sine rmse ~4f~n", [S]), fail ),
    ok(sine, S).

% ---- 5: a gaussian bump through relu layers ---------------------------------
bump_row(I, [X], [Y]) :- X is -2 + 4 * I / 159, Y is exp(-4 * X * X).
net_bump :-
    torch_seed(5),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(24, relu), dense(24, relu), dense(1)], M),
    model_train(M, X, Y, [epochs(500), batch(32), lr(0.02), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    S < 0.1, ok(bump, S).

% ---- 6: logistic regression, bce against a sigmoid head ---------------------
% Class is which side of a + b = 0 the point falls; accuracy counted by hand
% because a one-column argmax is always zero.
logi_row(I, [A, B], [L]) :-
    noise(I, A), noise(I + 500, B),
    ( A + B > 0 -> L = 1.0 ; L = 0.0 ).
net_logistic :-
    torch_seed(6),
    findall(R, (between(0, 159, I), logi_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), logi_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(2), dense(1, sigmoid)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.1), optimiser(adam), loss(bce)]),
    model_predict(M, X, P),
    tensor_to_list(P, Rows),
    findall(C, (member([V], Rows), ( V > 0.5 -> C = 1.0 ; C = 0.0 )), Pred),
    findall(L, member([L], YR), Lab),
    count_eq(Pred, Lab, K),
    length(Lab, N), Pct is K * 100 // N,
    Pct >= 95, S is Pct / 100, ok(logistic, S).

% ---- 7: xor, the net that needs the hidden layer ----------------------------
xor_point(I, [A, B], L) :-
    Q is I mod 4,
    ( Q =:= 0 -> A0 = 0, B0 = 0, L = 0
    ; Q =:= 1 -> A0 = 0, B0 = 1, L = 1
    ; Q =:= 2 -> A0 = 1, B0 = 0, L = 1
    ; A0 = 1, B0 = 1, L = 0 ),
    noise(I, E1), noise(I + 300, E2),
    A is A0 + 0.05 * E1, B is B0 + 0.05 * E2.
net_xor :-
    torch_seed(7),
    findall(R, (between(0, 127, I), xor_point(I, R, _)), XR),
    findall(L, (between(0, 127, I), xor_point(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(8, tanh), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(400), batch(16), lr(0.05), optimiser(adam), loss(nll)]),
    tensor_from_list([[0.0,0.0],[0.0,1.0],[1.0,0.0],[1.0,1.0]], Clean),
    tensor_from_list([0,1,1,0], CleanL),
    acc_percent(M, Clean, CleanL, Pct),
    Pct =:= 100, S is Pct / 100, ok(xor, S).

% ---- 8: two moons -----------------------------------------------------------
moon_row(I, [A, B], L) :-
    T is pi * (I mod 80) / 79,
    noise(I, E1), noise(I + 700, E2),
    ( I < 80
    -> L = 0, A is cos(T) + 0.1 * E1,      B is sin(T) + 0.1 * E2
    ;  L = 1, A is 1 - cos(T) + 0.1 * E1,  B is 0.4 - sin(T) + 0.1 * E2 ).
net_moons :-
    torch_seed(8),
    findall(R, (between(0, 159, I), moon_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), moon_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(16, relu), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 90, S is Pct / 100, ok(moons, S).

% ---- 9: four blobs, four classes --------------------------------------------
blob_row(I, [A, B], L) :-
    L is I mod 4,
    ( L =:= 0 -> CA = -1, CB = -1 ; L =:= 1 -> CA = -1, CB = 1
    ; L =:= 2 -> CA = 1,  CB = -1 ; CA = 1,  CB = 1 ),
    noise(I, E1), noise(I + 900, E2),
    A is CA + 0.3 * E1, B is CB + 0.3 * E2.
net_blobs :-
    torch_seed(9),
    findall(R, (between(0, 159, I), blob_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), blob_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(16, relu), dense(4, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 95, S is Pct / 100, ok(blobs, S).

% ---- 10: a three-arm spiral through a deeper net, raw logits ----------------
spiral_row(I, [A, B], L) :-
    L is I mod 3,
    K is I // 3,
    T is 0.4 + 3.5 * K / 59,
    Phi is T + L * 2 * pi / 3,
    noise(I, E1), noise(I + 1100, E2),
    A is 0.25 * T * cos(Phi) + 0.02 * E1,
    B is 0.25 * T * sin(Phi) + 0.02 * E2.
net_spiral :-
    torch_seed(10),
    findall(R, (between(0, 179, I), spiral_row(I, R, _)), XR),
    findall(L, (between(0, 179, I), spiral_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(32, relu), dense(32, relu), dense(3)], M),
    model_train(M, X, Y, [epochs(600), batch(32), lr(0.01), optimiser(adam), loss(cross_entropy)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 85, S is Pct / 100, ok(spiral, S).

% ---- 11: dropout, and OFF at predict time -----------------------------------
net_dropout :-
    torch_seed(11),
    findall(R, (between(0, 159, I), moon_row(I, R, _)), XR),
    findall(L, (between(0, 159, I), moon_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([input(2), dense(32, relu), dropout(0.3),
               dense(32, relu), dropout(0.3), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(300), batch(32), lr(0.02), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 85,
    % dropout must be inert at predict time: two forwards, one answer
    model_predict(M, X, P1), model_predict(M, X, P2),
    tensor_to_list(P1, R1), tensor_to_list(P2, R2),
    rows_close(R1, R2),
    S is Pct / 100, ok(dropout, S).

% ---- 12: sgd with a step schedule -------------------------------------------
net_schedule :-
    torch_seed(12),
    findall(R, (between(0, 159, I), bump_row(I, R, _)), XR),
    findall(R, (between(0, 159, I), bump_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(24, relu), dense(24, relu), dense(1)], M),
    model_train(M, X, Y, [epochs(1500), batch(32), lr(0.1), optimiser(sgd),
                          schedule(step, 400, 0.5), final_loss(_)]),
    model_evaluate(M, X, Y, rmse, S),
    ( S < 0.1 -> true ; format("      schedule rmse ~4f~n", [S]), fail ),
    ok(schedule, S).

% ---- 13: outliers in training, judged by mae on clean data ------------------
out_row(I, [X], [Y]) :-
    X is -1 + 2 * I / 119,
    noise(I, E),
    Y0 is 2 * X + 1 + 0.05 * E,
    ( I mod 10 =:= 0 -> Y is Y0 + 6 ; Y = Y0 ).
net_mae_outliers :-
    torch_seed(13),
    findall(R, (between(0, 119, I), out_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), out_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(1)], M),
    model_train(M, X, Y, [epochs(300), batch(24), lr(0.05), optimiser(adam)]),
    findall([C], (between(0, 39, I), X1 is -1 + 2 * I / 39, C is X1), CXR),
    findall([C], (between(0, 39, I), X1 is -1 + 2 * I / 39, C is 2 * X1 + 1), CYR),
    tensor_from_list(CXR, CX), tensor_from_list(CYR, CY),
    model_evaluate(M, CX, CY, mae, S),
    S < 0.6, ok(mae_outliers, S).

% ---- 14: an autoencoder squeezed through three units ------------------------
% Eight one-hot-ish patterns, jittered; 8 -> 3 -> 8 must reconstruct them.
ae_row(I, Row) :-
    H is I mod 8,
    findall(V, (between(0, 7, J),
                noise(I * 8 + J, E),
                ( J =:= H -> V is 1 + 0.05 * E ; V is 0.05 * E )), Row).
net_autoencoder :-
    torch_seed(14),
    findall(R, (between(0, 127, I), ae_row(I, R)), XR),
    tensor_from_list(XR, X),
    model_new([input(8), dense(8, tanh), dense(3, tanh), dense(8, tanh), dense(8)], M),
    model_train(M, X, X, [epochs(2000), batch(32), lr(0.01), optimiser(adam)]),
    model_evaluate(M, X, X, rmse, S),
    ( S < 0.15 -> true ; format("      autoencoder rmse ~4f~n", [S]), fail ),
    ok(autoencoder, S).

% ---- 15: denoising: noisy in, clean out -------------------------------------
dn_rows(I, Noisy, Clean) :-
    H is I mod 8,
    findall(V, (between(0, 7, J), ( J =:= H -> V = 1.0 ; V = 0.0 )), Clean),
    findall(V, (between(0, 7, J),
                noise(I * 8 + J + 40000, E),
                ( J =:= H -> V is 1 + 0.3 * E ; V is 0.3 * E )), Noisy).
net_denoise :-
    torch_seed(15),
    findall(R, (between(0, 127, I), dn_rows(I, R, _)), XR),
    findall(R, (between(0, 127, I), dn_rows(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(8), dense(8, tanh), dense(8)], M),
    model_train(M, X, Y, [epochs(800), batch(32), lr(0.02), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    S < 0.12, ok(denoise, S).

% ---- 16: two targets at once ------------------------------------------------
mo_row(I, [A, B], [S1, S2]) :-
    noise(I, A), noise(I + 1300, B),
    S1 is A + B, S2 is A - B.
net_multiout :-
    torch_seed(16),
    findall(R, (between(0, 119, I), mo_row(I, R, _)), XR),
    findall(R, (between(0, 119, I), mo_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(2), dense(2)], M),
    model_train(M, X, Y, [epochs(300), batch(24), lr(0.05), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    S < 0.05, ok(multiout, S).

% ---- images: bars and crosses on an 8x8 canvas ------------------------------
% Class 0 a vertical bar, class 1 a horizontal bar, class 2 both (a cross);
% the bar's position wanders, the pixels carry a little noise.
img_row(I, Classes, Row, L) :-
    L is I mod Classes,
    Pos is 1 + (I // Classes) mod 6,
    findall(V, (between(0, 63, P),
                R is P // 8, C is P mod 8,
                noise(I * 64 + P + 90000, E),
                ( L =:= 0 -> ( C =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E )
                ; L =:= 1 -> ( R =:= Pos -> V is 1 + 0.1 * E ; V is 0.1 * E )
                ; ( ( C =:= Pos ; R =:= Pos ) -> V is 1 + 0.1 * E ; V is 0.1 * E ) )),
            Row).

% ---- 17: one conv stage tells the two bars apart ----------------------------
net_cnn_bars :-
    torch_seed(17),
    findall(R, (between(0, 71, I), img_row(I, 2, R, _)), XR),
    findall(L, (between(0, 71, I), img_row(I, 2, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([image(1, 8, 8), conv(4, 3, relu), pool(2), flatten,
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(60), batch(12), lr(0.01), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 95, S is Pct / 100, ok(cnn_bars, S).

% ---- 18: two conv stages, three classes -------------------------------------
net_lenet_mini :-
    torch_seed(18),
    findall(R, (between(0, 89, I), img_row(I, 3, R, _)), XR),
    findall(L, (between(0, 89, I), img_row(I, 3, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([image(1, 8, 8),
               conv(4, 3, relu, pad(1)), pool(2),
               conv(8, 3, relu), flatten,
               dense(16, relu), dense(3, log_softmax)], M),
    model_train(M, X, Y, [epochs(80), batch(15), lr(0.01), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 95, S is Pct / 100, ok(lenet_mini, S).

% ---- 19: batch-norm, whose running statistics must serve at eval time -------
net_bn_cnn :-
    torch_seed(19),
    findall(R, (between(0, 71, I), img_row(I, 2, R, _)), XR),
    findall(L, (between(0, 71, I), img_row(I, 2, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([image(1, 8, 8), conv(4, 3, relu), norm, pool(2), flatten,
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(60), batch(12), lr(0.01), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 95, S is Pct / 100, ok(bn_cnn, S).

% ---- 20: the round trip through the knowledge base --------------------------
net_roundtrip :-
    torch_seed(20),
    findall(R, (between(0, 63, I), sine_row(I, R, _)), XR),
    findall(R, (between(0, 63, I), sine_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([input(1), dense(8, tanh), dense(1)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam)]),
    model_save(nets_roundtrip, M),
    model_load(nets_roundtrip, M2),
    model_params(M, P1), model_params(M2, P2),
    row_close(P1, P2),
    model_predict(M, X, T1), model_predict(M2, X, T2),
    tensor_to_list(T1, R1), tensor_to_list(T2, R2),
    rows_close(R1, R2),
    ok(roundtrip, 1.0).

% ---- 21: an lstm reads plain numbers and sums them --------------------------
sq_row(I, Row, [Y]) :-
    findall(V, (between(0, 7, J), noise(I * 8 + J + 60000, V)), Row),
    sum_row(Row, S), Y is S / 4.
sum_row([], 0).
sum_row([V|Vs], S) :- sum_row(Vs, S0), S is S0 + V.
net_seq_sum :-
    torch_seed(21),
    findall(R, (between(0, 127, I), sq_row(I, R, _)), XR),
    findall(R, (between(0, 127, I), sq_row(I, _, R)), YR),
    tensor_from_list(XR, X), tensor_from_list(YR, Y),
    model_new([sequence(8), lstm(16), dense(1)], M),
    model_train(M, X, Y, [epochs(400), batch(32), lr(0.02), optimiser(adam)]),
    model_evaluate(M, X, Y, rmse, S),
    ( S < 0.1 -> true ; format("      seq_sum rmse ~4f~n", [S]), fail ),
    ok(seq_sum, S).

% ---- 22: embedding + lstm remember whether token 3 ever appeared ------------
tok_row(I, Row, L) :-
    findall(T, (between(0, 5, J),
                noise(I * 6 + J + 70000, F),
                T is truncate(abs(F) * 7.99)), Row),
    ( member(3, Row) -> L = 1 ; L = 0 ).
net_seq_contains :-
    torch_seed(22),
    findall(R, (between(0, 95, I), tok_row(I, R, _)), XR),
    findall(L, (between(0, 95, I), tok_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([sequence(6), embedding(8, 4), lstm(16), dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam), loss(nll)]),
    acc_percent(M, X, Y, Pct),
    Pct >= 95, S is Pct / 100, ok(seq_contains, S).

% ---- 23: a stacked lstm through the store, weights and answers identical ----
net_seq_roundtrip :-
    torch_seed(23),
    findall(R, (between(0, 95, I), tok_row(I, R, _)), XR),
    findall(L, (between(0, 95, I), tok_row(I, _, L)), LR),
    tensor_from_list(XR, X), tensor_from_list(LR, Y),
    model_new([sequence(6), embedding(8, 4), lstm(12), lstm(12),
               dense(2, log_softmax)], M),
    model_train(M, X, Y, [epochs(200), batch(16), lr(0.02), optimiser(adam), loss(nll)]),
    model_save(nets_seq_roundtrip, M),
    model_load(nets_seq_roundtrip, M2),
    model_params(M, P1), model_params(M2, P2),
    row_close(P1, P2),
    model_predict(M, X, T1), model_predict(M2, X, T2),
    tensor_to_list(T1, R1), tensor_to_list(T2, R2),
    rows_close(R1, R2),
    ok(seq_roundtrip, 1.0).

% ---- the driver -------------------------------------------------------------
nets([net(linreg, net_linreg), net(multi_linreg, net_multi_linreg),
      net(polyreg, net_polyreg), net(sine, net_sine), net(bump, net_bump),
      net(logistic, net_logistic), net(xor, net_xor), net(moons, net_moons),
      net(blobs, net_blobs), net(spiral, net_spiral),
      net(dropout, net_dropout), net(schedule, net_schedule),
      net(mae_outliers, net_mae_outliers), net(autoencoder, net_autoencoder),
      net(denoise, net_denoise), net(multiout, net_multiout),
      net(cnn_bars, net_cnn_bars), net(lenet_mini, net_lenet_mini),
      net(bn_cnn, net_bn_cnn), net(roundtrip, net_roundtrip),
      net(seq_sum, net_seq_sum), net(seq_contains, net_seq_contains),
      net(seq_roundtrip, net_seq_roundtrip)]).

run_nets([], F, F).
run_nets([net(Name, G)|T], F0, F) :-
    ( catch(G, E, (format("FAIL  ~w: caught ~w~n", [Name, E]), fail))
    -> F1 = F0
    ; format("FAIL  ~w~n", [Name]), F1 is F0 + 1 ),
    run_nets(T, F1, F).

suite :-
    suite_device(D),
    torch_device(D),
    torch_current_device(CD),
    torch_cuda_available(A),
    format("device ~w (asked ~w, cuda available ~w)~n", [CD, D, A]),
    % on a box without CUDA, naming it must be a refusal, never a fallback
    ( A == false
    -> catch((torch_device(cuda), write('FAIL  cuda accepted without cuda'), nl, halt(1)),
             error(domain_error(cuda_available, _), _),
             (write('ok    cuda refused where absent'), nl)),
       torch_device(D)
    ; true ),
    nets(L),
    run_nets(L, 0, F),
    ( F =:= 0
    -> write('GREEN: 0 failure(s)'), nl
    ;  format("RED: ~w failure(s)~n", [F]), halt(1) ).
PL

echo "suite_device($DEVICE)." >> "$OUT/nets.pl"

timeout 900 "$COCOLOG" --kb torch_nets --embed "$STORE" run "$OUT/nets.pl" suite
