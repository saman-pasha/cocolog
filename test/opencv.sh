#!/bin/sh
# library(opencv): OpenCV as cocolog predicates, images as handles.
#
# WHAT IS BEING PINNED, in the order the module's header lists it:
#
#   AN IMAGE IS A HANDLE with a shape and a type; what goes in as rows
#   comes out as the same rows; a pixel reads and writes; a region is a
#   copy; a file written is a file read; a PNG encodes to its signature
#   and decodes back.
#
#   ARITHMETIC SATURATES, colour conversion uses OpenCV's weights, a
#   threshold is what the type says, a contour has the area and box of
#   what was drawn, a template is found where it was cut, a QR code made
#   here reads back, a homography from four exact pairs is exact.
#
#   A VIDEO WRITTEN IS A VIDEO READ, frame for frame, and reading fails
#   at the end. A dnn forward pass runs when a model is beside the
#   tutorials (tutorials/opencv/22-dnn-classification.pl download), and
#   is a SKIP line when it is not.
#
#   ERRORS ARE TERMS: a dead handle, a wrong type and a missing file each
#   raise error(cocolog_error(Text), _) with OpenCV's words, catchable.
#
#   NOTHING LEAKS: every handle a section makes is freed, and cv_handles
#   answers 0 at the end.
#
#   sh test/opencv.sh
#
# SKIPs without library/opencv.so (sh modules/opencv/build.sh says what it
# needs: an OpenCV 4 found through pkg-config).

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"
[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }
[ -f "$ROOT/library/opencv.so" ] || { echo "SKIP (no library/opencv.so -- sh modules/opencv/build.sh)"; exit 0; }
if ! timeout 60 "$C" --local query "use_module(library(opencv)), cv_new(1, 1, '8u', I), cv_free(I), write(ok), nl" 2>/dev/null | grep -aq '^ok$'; then
  echo "SKIP (library(opencv) does not start: is the OpenCV it was built against still here?)"
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
U="use_module(library(opencv))"
q() { timeout 180 "$C" --local query "$U, $1" 2>&1 | answer; }

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-opencv-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

echo "-- an image is a handle"
check "cv_new: shape [Rows, Cols, Channels] and the type it was made with" \
  "$(q "cv_new(4, 6, '8uc3', I), cv_shape(I, S), cv_type(I, T), cv_free(I), write(answer(S-T)), nl")" \
  "[4,6,3]-8uc3"
check "rows in, the same rows out; a float depth keeps floats" \
  "$(q "cv_from_list([[1,2,3],[4,5,6]], '8u', A), cv_to_list(A, L), cv_from_list([[1.5]], '64f', B), cv_to_list(B, M), cv_free_all([A,B]), write(answer(L-M)), nl")" \
  "[[1,2,3],[4,5,6]]-[[1.5]]"
check "cv_get and cv_set, a pixel per channel" \
  "$(q "cv_new(2, 2, '8uc3', I), cv_set(I, 1, 0, [7,8,9]), cv_get(I, 1, 0, P), cv_get(I, 0, 0, Z), cv_free(I), write(answer(P-Z)), nl")" \
  "[7,8,9]-[0,0,0]"
check "cv_roi copies [X, Y, W, H], x first" \
  "$(q "cv_from_list([[1,2,3],[4,5,6]], '8u', A), cv_roi(A, [1,0,2,2], R), cv_to_list(R, L), cv_free_all([A,R]), write(answer(L)), nl")" \
  "[[2,3],[5,6]]"
check "imwrite then imread, and gray on the way back" \
  "$(q "cv_new(3, 5, '8uc3', [10,20,30], I), cv_imwrite('$OUT/a.png', I), cv_imread('$OUT/a.png', J), cv_imread('$OUT/a.png', gray, G), cv_get(J, 0, 0, P), cv_shape(G, S), cv_free_all([I,J,G]), write(answer(P-S)), nl")" \
  "[10,20,30]-[3,5,1]"
check "a PNG starts with its signature and decodes back" \
  "$(q "cv_from_list([[1,2],[3,4]], '8u', A), cv_encode('.png', A, [B0,B1,B2,B3|_]), cv_encode('.png', A, Bs), cv_decode(Bs, D), cv_to_list(D, L), cv_free_all([A,D]), write(answer([B0,B1,B2,B3]-L)), nl")" \
  "[137,80,78,71]-[[1,2],[3,4]]"

echo "-- arithmetic, colour, threshold"
check "8u arithmetic saturates" \
  "$(q "cv_from_list([[200,100,0]], '8u', A), cv_from_list([[100,100,100]], '8u', B), cv_add(A, B, S), cv_sub(A, B, D), cv_to_list(S, SL), cv_to_list(D, DL), cv_free_all([A,B,S,D]), write(answer(SL-DL)), nl")" \
  "[[255,200,100]]-[[100,0,0]]"
check "blue, green, red, white to grey with OpenCV's weights" \
  "$(q "cv_from_list([[[255,0,0],[0,255,0],[0,0,255],[255,255,255]]], '8uc3', P), cv_gray(P, G), cv_to_list(G, L), cv_free_all([P,G]), write(answer(L)), nl")" \
  "[[29,150,76,255]]"
check "HSV hue: red 0, green 60, blue 120" \
  "$(q "cv_from_list([[[255,0,0],[0,255,0],[0,0,255]]], '8uc3', P), cv_cvt_color(P, bgr2hsv, H), cv_to_list(H, [[[HB|_],[HG|_],[HR|_]]]), cv_free_all([P,H]), write(answer([HR,HG,HB])), nl")" \
  "[0,60,120]"
check "the five threshold types at T = 100" \
  "$(q "cv_from_list([[0,50,100,150,200,250]], '8u', V), findall(L, (member(T, [binary,binary_inv,trunc,tozero,tozero_inv]), cv_threshold(V, 100, 255, T, O), cv_to_list(O, [L]), cv_free(O)), Ls), cv_free(V), write(answer(Ls)), nl")" \
  "[[0,0,0,255,255,255],[255,255,255,0,0,0],[0,50,100,100,100,100],[0,0,0,150,200,250],[0,50,100,0,0,0]]"
check "mean, minmax with locations, count_nonzero" \
  "$(q "cv_from_list([[5,1],[9,3]], '8u', Q), cv_mean(Q, M), cv_minmax(Q, Lo, Hi, LoAt, HiAt), cv_count_nonzero(Q, N), cv_free(Q), write(answer(M-Lo-Hi-LoAt-HiAt-N)), nl")" \
  "[4.5]-1.0-9.0-[1,0]-[0,1]-4"

echo "-- resampling: Pillow's filters, vendored; the numbers are Pillow 11.3.0's own"
check "box halves [0,0,255,255] to [0,255]" \
  "$(q "cv_from_list([[0,0,255,255]], '8u', A), cv_resample(A, [2,1], box, B), cv_to_list(B, L), cv_free_all([A,B]), write(answer(L)), nl")" \
  "[[0,255]]"
check "bilinear, hamming, bicubic, lanczos on the same row" \
  "$(q "cv_from_list([[0,0,255,255]], '8u', A), findall(V, ( member(F, [bilinear,hamming,bicubic,lanczos]), cv_resample(A, [2,1], F, B), cv_to_list(B, [V]), cv_free(B) ), Vs), cv_free(A), write(answer(Vs)), nl")" \
  "[[36,219],[10,245],[21,234],[18,237]]"
check "bilinear on a 4x4 ramp to 2x2" \
  "$(q "cv_from_list([[0,16,32,48],[64,80,96,112],[128,144,160,176],[192,208,224,240]], '8u', A), cv_resample(A, [2,2], bilinear, B), cv_to_list(B, L), cv_free_all([A,B]), write(answer(L)), nl")" \
  "[[57,83],[157,183]]"
check "bilinear upscales too: [0,255] to six" \
  "$(q "cv_from_list([[0,255]], '8u', A), cv_resample(A, [6,1], bilinear, B), cv_to_list(B, [L]), cv_free_all([A,B]), write(answer(L)), nl")" \
  "[0,0,85,170,255,255]"
check "three channels are three bands, each resampled alone" \
  "$(q "cv_from_list([[[0,255,0],[0,255,0],[255,0,255],[255,0,255]]], '8uc3', A), cv_resample(A, [2,1], bilinear, B), cv_to_list(B, L), cv_free_all([A,B]), write(answer(L)), nl")" \
  "[[[36,219,36],[219,36,219]]]"
check "a view of a bigger picture resamples as itself" \
  "$(q "cv_from_list([[9,0,0,255,255,9]], '8u', A), cv_roi(A, [1,0,4,1], R), cv_resample(R, [2,1], bilinear, B), cv_to_list(B, L), cv_free_all([A,R,B]), write(answer(L)), nl")" \
  "[[36,219]]"
check "an unknown filter is a domain error" \
  "$(q "cv_from_list([[1,2]], '8u', A), catch(cv_resample(A, [1,1], nearest, _), error(cocolog_error(M), _), true), cv_free(A), write(answer(M)), nl")" \
  "opencv: unknown resampling filter: nearest"

echo "-- shapes"
check "a filled 40 by 30 rectangle: one contour, its box, its pixel-polygon area" \
  "$(q "cv_new(100, 100, '8u', 0, I), cv_rectangle(I, [20,20,40,30], 255, -1), cv_find_contours(I, external, simple, [C]), cv_contour_area(C, A), cv_bounding_rect(C, R), cv_free(I), write(answer(A-R)), nl")" \
  "1131.0-[20,20,40,30]"
check "erode and dilate a 10 by 10 square by a 3 by 3" \
  "$(q "cv_new(30, 30, '8u', 0, S), cv_rectangle(S, [10,10,10,10], 255, -1), cv_erode(S, 3, E), cv_dilate(S, 3, D), cv_count_nonzero(E, NE), cv_count_nonzero(D, ND), cv_free_all([S,E,D]), write(answer(NE-ND)), nl")" \
  "64-144"
check "a template is found where it was cut" \
  "$(q "cv_new(64, 64, '8uc3', [40,40,40], I), cv_circle(I, [30,30], 10, red, -1), cv_roi(I, [20,20,20,20], T), cv_match_template(I, T, ccoeff_normed, R), cv_minmax(R, _, _, _, At), cv_free_all([I,T,R]), write(answer(At)), nl")" \
  "[20,20]"
check "an affine map from three pairs is exact" \
  "$(q "cv_affine_transform([[0,0],[10,0],[0,10]], [[5,3],[15,3],[5,13]], M), write(answer(M)), nl")" \
  "[[1.0,0.0,5.0],[0.0,1.0,3.0]]"
check "a homography from a doubling doubles a point" \
  "$(q "cv_perspective_transform([[0,0],[100,0],[100,100],[0,100]], [[0,0],[200,0],[200,200],[0,200]], M), cv_transform_points([[10,20]], M, P), write(answer(P)), nl")" \
  "[[20.0,40.0]]"
# Ubuntu 22.04's OpenCV 4.5.4 has no cv::QRCodeEncoder; the module then says so
# from cv_qr_encode, and the round trip is a SKIP line, not a red.
if [ "$(q "catch(cv_qr_encode(x, Q), error(cocolog_error(_), _), fail) -> cv_free(Q), write(answer(yes)), nl ; write(answer(no)), nl")" = yes ]; then
  HAVE_QRENC=yes
  check "a QR code made here reads back, with four corners" \
    "$(q "cv_qr_encode('cocolog', Q), cv_resize(Q, 6, nearest, B), cv_qr_detect(B, T, Ps), length(Ps, N), cv_free_all([Q,B]), write(answer(T-N)), nl")" \
    "cocolog-4"
else
  HAVE_QRENC=no
  echo "SKIP the QR round trip (this OpenCV was built without cv::QRCodeEncoder)"
fi
check "ORB descriptors: 32 bytes per keypoint, matches index them as integers" \
  "$(q "cv_new(128, 128, '8uc3', [40,40,40], I), cv_rectangle(I, [30,30,40,50], white, -1), cv_circle(I, [90,80], 20, red, -1), cv_put_text(I, abc, [10,120], 0.8, yellow, 2), cv_features(orb, I, K, D), cv_shape(D, [N,32,1]), cv_match(D, D, hamming, [[Q,T,Dist]|_]), ( integer(Q), integer(T), Dist =:= 0 -> R = self_match ; R = [Q,T,Dist] ), cv_free_all([I,D]), write(answer(R)), nl")" \
  "self_match"

echo "-- video"
check "twelve frames written are twelve frames read, and then reading fails" \
  "$(q "cv_video_writer('$OUT/v.avi', 'MJPG', 10.0, [64,48], W), forall(between(1, 12, K), (cv_new(48, 64, '8uc3', [K,K,K], F), cv_video_write(W, F), cv_free(F))), cv_free(W), cv_video_open('$OUT/v.avi', V), cv_video_prop(V, frames, NF), forall(between(1, 12, _), (cv_video_read(V, Fr), cv_free(Fr))), ( cv_video_read(V, _) -> E = more ; E = ended ), cv_free(V), write(answer(NF-E)), nl")" \
  "12.0-ended"
check "background subtraction sees a mover and not the ground" \
  "$(q "cv_bgsub_new(mog2, B), forall(between(0, 9, K), (cv_new(60, 80, '8uc3', [90,90,90], F), X is 10 + 4 * K, cv_rectangle(F, [X,20,16,16], white, -1), cv_bgsub_apply(B, F, M), cv_free_all([F,M]))), cv_new(60, 80, '8uc3', [90,90,90], G), cv_rectangle(G, [50,20,16,16], white, -1), cv_bgsub_apply(B, G, Mk), cv_roi(Mk, [0,0,8,60], L), cv_count_nonzero(Mk, N), cv_count_nonzero(L, NL), cv_free_all([B,G,Mk,L]), ( N > 50, NL =:= 0 -> R = mover_only ; R = N-NL ), write(answer(R)), nl")" \
  "mover_only"

echo "-- dnn"
if [ -f "$ROOT/tutorials/opencv/models/squeezenet1.1-7.onnx" ]; then
  # the class index belongs to the CURRENT 42-detection-1.jpg -- tutorial 42's predict
  # redraws the photographs, and a new picture is a new class (602, 480, 843 so far)
  check "SqueezeNet forward: 1 by 1000, and the class it names for the walkers" \
    "$(cd "$ROOT" && q "cv_dnn_read('tutorials/opencv/models/squeezenet1.1-7.onnx', N), cv_imread('tutorials/tensor/42-detection-1.jpg', I), cv_dnn_blob(I, 0.017353, [224,224], [123.675,116.28,103.53], true, true, B), cv_dnn_input(N, B), cv_dnn_forward(N, O), cv_shape(O, S), cv_dnn_top(O, C, _), cv_free_all([N,I,B,O]), write(answer(S-C)), nl")" \
    "[1,1000,1]-843"
else
  echo "SKIP dnn (no tutorials/opencv/models/squeezenet1.1-7.onnx -- ./cocolog run tutorials/opencv/22-dnn-classification.pl download)"
fi

echo "-- errors are terms"
check "a dead handle" \
  "$(q "catch(cv_shape(12345, _), error(cocolog_error(M), _), true), write(answer(M)), nl")" \
  "opencv: not a live handle: 12345"
check "an unknown type names the argument's fault" \
  "$(q "catch(cv_new(1, 1, '7u', _), error(cocolog_error(M), _), true), write(answer(M)), nl")" \
  "opencv: unknown image type: 7u"
check "a missing file, in OpenCV's words" \
  "$(q "catch(cv_imread('/no/such.png', _), error(cocolog_error(M), _), true), write(answer(M)), nl")" \
  "opencv: cannot read image: /no/such.png"
check "an unbound argument" \
  "$(q "catch(cv_shape(_, _), error(cocolog_error(M), _), true), write(answer(M)), nl")" \
  "opencv: argument 1 must be bound"

echo "-- nothing leaks"
check "cv_handles is 0 after a session that made and freed" \
  "$(q "cv_new(2, 2, '8uc3', A), cv_gray(A, G), cv_split(A, Cs), cv_free_all([A, G|Cs]), ( catch(cv_qr_encode(x, Q), _, fail) -> cv_free(Q) ; true ), cv_handles(N), write(answer(N)), nl")" \
  "0"

if [ "$failures" -eq 0 ]; then echo "GREEN: opencv"; else echo "RED: $failures failure(s)"; exit 1; fi
